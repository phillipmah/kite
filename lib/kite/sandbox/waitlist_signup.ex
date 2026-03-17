defmodule Kite.Sandbox.WaitlistSignup do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sandbox_waitlist_signups" do
    field :email, :string
    field :source, :string, default: "sandbox"

    belongs_to :conversation, Kite.Sandbox.Conversation

    timestamps(updated_at: false)
  end

  def changeset(signup, attrs) do
    signup
    |> cast(attrs, [:email, :conversation_id, :source])
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "must be a valid email")
    |> unique_constraint(:email)
  end
end
