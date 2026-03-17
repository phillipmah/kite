defmodule Kite.Sandbox.Models do
  @models [
    %{id: "claude", name: "Claude", provider: :anthropic, model_id: "claude-opus-4-5"},
    %{id: "gpt4", name: "GPT-4", provider: :openai, model_id: "gpt-4o"},
    %{id: "gemini", name: "Gemini", provider: :google, model_id: "gemini-1.5-flash"},
    %{id: "llama", name: "Llama", provider: :together, model_id: "meta-llama/Llama-3-70b-chat-hf"},
    %{id: "mistral", name: "Mistral", provider: :mistral, model_id: "mistral-large-latest"}
  ]

  def all, do: @models

  def find(id), do: Enum.find(@models, &(&1.id == id))

  def name(id) do
    case find(id) do
      %{name: name} -> name
      nil -> id
    end
  end

  def ids, do: Enum.map(@models, & &1.id)
end
