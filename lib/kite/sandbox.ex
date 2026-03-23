defmodule Kite.Sandbox do
  @moduledoc """
  Context for the Model Sandbox feature.
  Handles conversation and message logging, and waitlist signups.
  """

  import Ecto.Query
  alias Kite.Repo
  alias Kite.Sandbox.{Conversation, Message, WaitlistSignup}

  # --- Conversations ---

  def create_conversation(attrs) do
    %Conversation{}
    |> Conversation.changeset(attrs)
    |> Repo.insert()
  end

  # --- Messages ---

  def log_message(attrs) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  def log_message_async(attrs) do
    Task.start(fn -> log_message(attrs) end)
  end

  # --- Waitlist ---

  def signup_for_waitlist(attrs) do
    %WaitlistSignup{}
    |> WaitlistSignup.changeset(attrs)
    |> Repo.insert()
  end

  def already_on_waitlist?(email) do
    Repo.exists?(from w in WaitlistSignup, where: w.email == ^email)
  end

  # --- System prompt ---

  def build_system_prompt(child_age, family_context, custom_context) do
    age_desc = age_description(child_age)
    family_addition = family_context_text(family_context, custom_context)

    """
    You are a helpful, friendly AI assistant having a conversation with a #{age_desc} child.

    Keep your responses:
    - Age-appropriate for a #{age_desc}
    - Clear, simple, and easy to understand
    - Warm, encouraging, and patient
    - Honest but sensitive to the child's developmental stage
    - Free from inappropriate content

    Use simple vocabulary and relatable examples suitable for a #{age_desc}.
    #{family_addition}
    Respond conversationally and keep answers concise.
    """
  end

  defp age_description("5"), do: "5 year old"
  defp age_description("7"), do: "7 year old"
  defp age_description("10"), do: "10 year old"
  defp age_description("12"), do: "12 year old"
  defp age_description("teenager"), do: "teenage"
  defp age_description(age), do: age

  defp family_context_text("none", _), do: ""

  defp family_context_text("conservative_religious", _),
    do:
      "This child comes from a conservative religious family. Be respectful of their faith, values, and beliefs."

  defp family_context_text("secular", _),
    do:
      "This child comes from a secular family that values science, reason, and evidence-based thinking."

  defp family_context_text("single_parent", _),
    do: "This child lives in a single parent household."

  defp family_context_text("multilingual", _),
    do: "This child lives in a multilingual household and may be learning multiple languages."

  defp family_context_text("custom", custom) when is_binary(custom) and custom != "",
    do: "Additional context about this child's family: #{custom}"

  defp family_context_text(_, _), do: ""
end
