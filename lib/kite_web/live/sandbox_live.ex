defmodule KiteWeb.SandboxLive do
  use KiteWeb, :live_view

  alias Kite.Sandbox
  alias Kite.Sandbox.{AIClient, Models, RateLimiter}

  @free_message_limit 5

  @welcome_message %{
    role: "assistant",
    content: "Hi! I'm here to help answer questions. What would you like to know about?",
    model: "claude",
    sent_at: nil
  }

  @impl true
  def mount(_params, _session, socket) do
    session_id = generate_session_id()
    ip = get_client_ip(socket)

    socket =
      socket
      |> assign(:page_title, "Model Sandbox")
      |> assign(:model, "claude")
      |> assign(:child_age, "10")
      |> assign(:family_context, "none")
      |> assign(:custom_context, "")
      |> assign(:messages, [@welcome_message])
      |> assign(:messages_remaining, @free_message_limit)
      |> assign(:loading, false)
      |> assign(:show_waitlist_gate, false)
      |> assign(:waitlist_email, "")
      |> assign(:waitlist_error, nil)
      |> assign(:waitlist_submitted, false)
      |> assign(:daily_limit_reached, false)
      |> assign(:session_id, session_id)
      |> assign(:ip, ip)
      |> assign(:conversation_id, nil)
      |> assign(:message_input, "")

    {:ok, socket}
  end

  @impl true
  def handle_event("update_model", %{"model" => model}, socket) do
    if model in Models.ids() do
      {:noreply, assign(socket, :model, model)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("update_child_age", %{"child_age" => age}, socket) do
    {:noreply, assign(socket, :child_age, age)}
  end

  def handle_event("update_family_context", %{"family_context" => context}, socket) do
    {:noreply, assign(socket, :family_context, context)}
  end

  def handle_event("update_custom_context", %{"custom_context" => text}, socket) do
    {:noreply, assign(socket, :custom_context, text)}
  end

  def handle_event("send_message", %{"message" => text}, socket) do
    text = String.trim(text)

    cond do
      text == "" ->
        {:noreply, socket}

      socket.assigns.loading ->
        {:noreply, socket}

      socket.assigns.messages_remaining <= 0 ->
        {:noreply, assign(socket, :show_waitlist_gate, true)}

      true ->
        send_message(socket, text)
    end
  end

  def handle_event("submit_waitlist", %{"email" => email}, socket) do
    email = String.trim(email)
    conversation_id = socket.assigns.conversation_id

    case Sandbox.signup_for_waitlist(%{email: email, conversation_id: conversation_id}) do
      {:ok, _} ->
        {:noreply, assign(socket, :waitlist_submitted, true)}

      {:error, changeset} ->
        error =
          if Keyword.has_key?(changeset.errors, :email) do
            {msg, _} = changeset.errors[:email]
            msg
          else
            "Something went wrong. Please try again."
          end

        {:noreply, assign(socket, :waitlist_error, error)}
    end
  end

  def handle_event("dismiss_waitlist", _params, socket) do
    {:noreply, assign(socket, :show_waitlist_gate, false)}
  end

  @impl true
  def handle_async(:ai_response, {:ok, {text, latency_ms}}, socket) do
    model = socket.assigns.model

    ai_message = %{
      role: "assistant",
      content: text,
      model: model,
      sent_at: DateTime.utc_now()
    }

    messages = socket.assigns.messages ++ [ai_message]
    remaining = socket.assigns.messages_remaining

    # Log AI message to DB asynchronously
    if conversation_id = socket.assigns.conversation_id do
      Sandbox.log_message_async(%{
        conversation_id: conversation_id,
        role: "assistant",
        content: text,
        latency_ms: latency_ms
      })
    end

    socket =
      socket
      |> assign(:messages, messages)
      |> assign(:loading, false)

    # Show waitlist gate after AI responds to the last free message
    socket =
      if remaining <= 0 do
        assign(socket, :show_waitlist_gate, true)
      else
        socket
      end

    {:noreply, push_event(socket, "scroll-to-bottom", %{})}
  end

  def handle_async(:ai_response, {:exit, reason}, socket) do
    error_message = %{
      role: "assistant",
      content: "Sorry, I couldn't get a response. Please try again. (#{format_error(reason)})",
      model: socket.assigns.model,
      sent_at: DateTime.utc_now()
    }

    messages = socket.assigns.messages ++ [error_message]

    socket =
      socket
      |> assign(:messages, messages)
      |> assign(:loading, false)

    {:noreply, socket}
  end

  # --- Private helpers ---

  defp send_message(socket, text) do
    ip = socket.assigns.ip

    case RateLimiter.check_and_increment(ip) do
      {:error, :rate_limited} ->
        {:noreply, assign(socket, :daily_limit_reached, true)}

      {:ok, _remaining} ->
        user_message = %{
          role: "user",
          content: text,
          model: nil,
          sent_at: DateTime.utc_now()
        }

        messages = socket.assigns.messages ++ [user_message]
        new_remaining = socket.assigns.messages_remaining - 1

        # Create or reuse conversation record
        conversation_id =
          socket.assigns.conversation_id ||
            create_conversation_record(socket)

        # Log user message asynchronously
        if conversation_id do
          Sandbox.log_message_async(%{
            conversation_id: conversation_id,
            role: "user",
            content: text
          })
        end

        # Build context for AI call
        model = socket.assigns.model
        child_age = socket.assigns.child_age
        family_context = socket.assigns.family_context
        custom_context = socket.assigns.custom_context
        system_prompt = Sandbox.build_system_prompt(child_age, family_context, custom_context)

        # Only send non-system messages to the API
        api_messages =
          Enum.filter(messages, &(&1.role in ["user", "assistant"]))
          |> Enum.map(&Map.take(&1, [:role, :content]))

        socket =
          socket
          |> assign(:messages, messages)
          |> assign(:messages_remaining, new_remaining)
          |> assign(:loading, true)
          |> assign(:message_input, "")
          |> assign(:conversation_id, conversation_id)
          |> start_async(:ai_response, fn ->
            start = System.monotonic_time(:millisecond)
            result = AIClient.chat(model, api_messages, system_prompt)
            latency = System.monotonic_time(:millisecond) - start

            case result do
              {:ok, text} -> {text, latency}
              {:error, reason} -> raise reason
            end
          end)

        {:noreply, push_event(socket, "scroll-to-bottom", %{})}
    end
  end

  defp create_conversation_record(socket) do
    attrs = %{
      session_id: socket.assigns.session_id,
      ip_address: socket.assigns.ip,
      model: socket.assigns.model,
      child_age: socket.assigns.child_age,
      family_context: socket.assigns.family_context,
      custom_context: socket.assigns.custom_context
    }

    case Sandbox.create_conversation(attrs) do
      {:ok, conv} -> conv.id
      {:error, _} -> nil
    end
  end

  defp generate_session_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end

  defp get_client_ip(socket) do
    case get_connect_info(socket, :peer_data) do
      %{address: addr} ->
        addr
        |> :inet.ntoa()
        |> List.to_string()

      _ ->
        "unknown"
    end
  end

  defp format_error(reason) when is_binary(reason), do: reason
  defp format_error(reason), do: inspect(reason)

  # --- View helpers ---

  def age_label("5"), do: "5 years old"
  def age_label("7"), do: "7 years old"
  def age_label("10"), do: "10 years old"
  def age_label("12"), do: "12 years old"
  def age_label("teenager"), do: "Teenager"
  def age_label(age), do: age

  def family_label("none"), do: "No context"
  def family_label("conservative_religious"), do: "Conservative religious"
  def family_label("secular"), do: "Secular"
  def family_label("single_parent"), do: "Single parent"
  def family_label("multilingual"), do: "Multilingual"
  def family_label("custom"), do: "Custom"
  def family_label(ctx), do: ctx

  def context_summary(model, child_age) do
    "#{Models.name(model)} · Child is #{age_label(child_age)}"
  end
end
