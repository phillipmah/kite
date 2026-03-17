defmodule Kite.Sandbox.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sandbox_messages" do
    field :role, :string
    field :content, :string
    field :latency_ms, :integer

    belongs_to :conversation, Kite.Sandbox.Conversation

    timestamps(updated_at: false)
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:conversation_id, :role, :content, :latency_ms])
    |> validate_required([:conversation_id, :role, :content])
    |> validate_inclusion(:role, ["user", "assistant"])
  end
end
