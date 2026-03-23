defmodule Kite.Sandbox.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sandbox_conversations" do
    field :session_id, :string
    field :ip_address, :string
    field :model, :string
    field :child_age, :string
    field :family_context, :string
    field :custom_context, :string

    has_many :messages, Kite.Sandbox.Message

    timestamps(updated_at: false)
  end

  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [
      :session_id,
      :ip_address,
      :model,
      :child_age,
      :family_context,
      :custom_context
    ])
    |> validate_required([:session_id, :model, :child_age, :family_context])
  end
end
