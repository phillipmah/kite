defmodule Kite.Sandbox.AIClient do
  @moduledoc """
  Handles AI API calls for the Model Sandbox.
  Supports Claude (Anthropic), GPT-4 (OpenAI), Gemini (Google),
  Llama (via Together AI), and Mistral.
  """

  alias Kite.Sandbox.Models

  @max_tokens 1024

  @doc """
  Send messages to the selected model. Returns {:ok, text} or {:error, reason}.
  messages is a list of %{role: "user"|"assistant", content: string} in order.
  """
  def chat(model_id, messages, system_prompt) do
    case Models.find(model_id) do
      nil -> {:error, "Unknown model: #{model_id}"}
      model -> call_provider(model, messages, system_prompt)
    end
  end

  defp call_provider(%{provider: :anthropic} = model, messages, system_prompt) do
    api_key = System.get_env("ANTHROPIC_API_KEY")

    if is_nil(api_key) do
      {:ok, demo_response("Claude")}
    else
      body = %{
        model: model.model_id,
        max_tokens: @max_tokens,
        system: system_prompt,
        messages: format_messages_basic(messages)
      }

      case Req.post("https://api.anthropic.com/v1/messages",
             headers: [
               {"x-api-key", api_key},
               {"anthropic-version", "2023-06-01"}
             ],
             json: body,
             receive_timeout: 30_000
           ) do
        {:ok, %{status: 200, body: body}} ->
          text = get_in(body, ["content", Access.at(0), "text"])
          {:ok, text}

        {:ok, %{status: status, body: body}} ->
          {:error, "Claude API error #{status}: #{Map.get(body, "error", %{}) |> Map.get("message", "unknown")}"}

        {:error, reason} ->
          {:error, "Claude request failed: #{inspect(reason)}"}
      end
    end
  end

  defp call_provider(%{provider: :openai} = model, messages, system_prompt) do
    api_key = System.get_env("OPENAI_API_KEY")

    if is_nil(api_key) do
      {:ok, demo_response("GPT-4")}
    else
      all_messages =
        [%{"role" => "system", "content" => system_prompt}] ++
          format_messages_basic(messages)

      body = %{
        model: model.model_id,
        messages: all_messages,
        max_tokens: @max_tokens
      }

      case Req.post("https://api.openai.com/v1/chat/completions",
             headers: [{"Authorization", "Bearer #{api_key}"}],
             json: body,
             receive_timeout: 30_000
           ) do
        {:ok, %{status: 200, body: body}} ->
          text = get_in(body, ["choices", Access.at(0), "message", "content"])
          {:ok, text}

        {:ok, %{status: status, body: body}} ->
          msg = get_in(body, ["error", "message"]) || "unknown"
          {:error, "GPT-4 API error #{status}: #{msg}"}

        {:error, reason} ->
          {:error, "GPT-4 request failed: #{inspect(reason)}"}
      end
    end
  end

  defp call_provider(%{provider: :google} = model, messages, system_prompt) do
    api_key = System.get_env("GOOGLE_AI_API_KEY")

    if is_nil(api_key) do
      {:ok, demo_response("Gemini")}
    else
      contents =
        Enum.map(messages, fn %{role: role, content: content} ->
          gemini_role = if role == "assistant", do: "model", else: "user"
          %{"role" => gemini_role, "parts" => [%{"text" => content}]}
        end)

      body = %{
        "contents" => contents,
        "systemInstruction" => %{
          "parts" => [%{"text" => system_prompt}]
        },
        "generationConfig" => %{
          "maxOutputTokens" => @max_tokens
        }
      }

      url =
        "https://generativelanguage.googleapis.com/v1beta/models/#{model.model_id}:generateContent?key=#{api_key}"

      case Req.post(url, json: body, receive_timeout: 30_000) do
        {:ok, %{status: 200, body: body}} ->
          text = get_in(body, ["candidates", Access.at(0), "content", "parts", Access.at(0), "text"])
          {:ok, text}

        {:ok, %{status: status, body: body}} ->
          msg = get_in(body, ["error", "message"]) || "unknown"
          {:error, "Gemini API error #{status}: #{msg}"}

        {:error, reason} ->
          {:error, "Gemini request failed: #{inspect(reason)}"}
      end
    end
  end

  defp call_provider(%{provider: :together} = model, messages, system_prompt) do
    api_key = System.get_env("TOGETHER_API_KEY")

    if is_nil(api_key) do
      {:ok, demo_response("Llama")}
    else
      all_messages =
        [%{"role" => "system", "content" => system_prompt}] ++
          format_messages_basic(messages)

      body = %{
        model: model.model_id,
        messages: all_messages,
        max_tokens: @max_tokens
      }

      case Req.post("https://api.together.xyz/v1/chat/completions",
             headers: [{"Authorization", "Bearer #{api_key}"}],
             json: body,
             receive_timeout: 30_000
           ) do
        {:ok, %{status: 200, body: body}} ->
          text = get_in(body, ["choices", Access.at(0), "message", "content"])
          {:ok, text}

        {:ok, %{status: status, body: body}} ->
          msg = get_in(body, ["error", "message"]) || "unknown"
          {:error, "Llama API error #{status}: #{msg}"}

        {:error, reason} ->
          {:error, "Llama request failed: #{inspect(reason)}"}
      end
    end
  end

  defp call_provider(%{provider: :mistral} = model, messages, system_prompt) do
    api_key = System.get_env("MISTRAL_API_KEY")

    if is_nil(api_key) do
      {:ok, demo_response("Mistral")}
    else
      all_messages =
        [%{"role" => "system", "content" => system_prompt}] ++
          format_messages_basic(messages)

      body = %{
        model: model.model_id,
        messages: all_messages,
        max_tokens: @max_tokens
      }

      case Req.post("https://api.mistral.ai/v1/chat/completions",
             headers: [{"Authorization", "Bearer #{api_key}"}],
             json: body,
             receive_timeout: 30_000
           ) do
        {:ok, %{status: 200, body: body}} ->
          text = get_in(body, ["choices", Access.at(0), "message", "content"])
          {:ok, text}

        {:ok, %{status: status, body: body}} ->
          msg = get_in(body, ["error", "message"]) || "unknown"
          {:error, "Mistral API error #{status}: #{msg}"}

        {:error, reason} ->
          {:error, "Mistral request failed: #{inspect(reason)}"}
      end
    end
  end

  # Convert internal message format to basic {role, content} maps for most providers
  defp format_messages_basic(messages) do
    Enum.map(messages, fn %{role: role, content: content} ->
      %{"role" => role, "content" => content}
    end)
  end

  defp demo_response(model_name) do
    """
    Hi there! I'm #{model_name}, and I'm here to help answer your questions. \
    (Note: This is a demo response — add an API key to enable real AI responses.) \
    What would you like to know about?
    """
  end
end
