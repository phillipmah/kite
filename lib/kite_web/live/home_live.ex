defmodule KiteWeb.HomeLive do
  use KiteWeb, :live_view

  alias Kite.Waitlist
  alias Kite.Waitlist.Entry

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Kite — AI built for families")
     |> assign(:hero_form, to_form(Waitlist.change_entry(%Entry{}), as: "entry"))
     |> assign(:form, to_form(Waitlist.change_entry(%Entry{})))
     |> assign(:hero_phase, :form)
     |> assign(:entry_id, nil)
     |> assign(:submitted, false)}
  end

  # Bottom form validation
  def handle_event("validate", %{"entry" => params}, socket) do
    form =
      %Entry{}
      |> Waitlist.change_entry(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  # Hero form validation (email only)
  def handle_event("validate_hero", %{"entry" => params}, socket) do
    hero_form =
      %Entry{}
      |> Waitlist.change_entry(params)
      |> Map.put(:action, :validate)
      |> to_form(as: "entry")

    {:noreply, assign(socket, :hero_form, hero_form)}
  end

  # Hero form submit — email only, then show survey
  def handle_event("hero_submit", %{"entry" => %{"email" => email}}, socket) do
    case Waitlist.join_waitlist(%{"email" => email}) do
      {:ok, entry} ->
        {:noreply,
         socket
         |> assign(:hero_phase, :survey)
         |> assign(:entry_id, entry.id)}

      {:error, changeset} ->
        {:noreply, assign(socket, :hero_form, to_form(changeset, as: "entry"))}
    end
  end

  # Survey submit
  def handle_event("submit_survey", %{"survey" => params}, socket) do
    if socket.assigns.entry_id do
      entry = Waitlist.get_entry!(socket.assigns.entry_id)
      Waitlist.update_survey(entry, params)
    end

    {:noreply, assign(socket, :hero_phase, :done)}
  end

  # Skip survey
  def handle_event("skip_survey", _params, socket) do
    {:noreply, assign(socket, :hero_phase, :done)}
  end

  # Bottom form submit — name + email, no survey
  def handle_event("submit", %{"entry" => params}, socket) do
    case Waitlist.join_waitlist(params) do
      {:ok, _entry} ->
        {:noreply, assign(socket, :submitted, true)}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
