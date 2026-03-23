defmodule Kite.Waitlist.Entry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "waitlist_entries" do
    field :name, :string
    field :email, :string
    field :child_ages, {:array, :string}, default: []
    field :worries, {:array, :string}, default: []
    field :top_priority, :string

    timestamps(updated_at: false)
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:name, :email])
    |> validate_required([:email])
    |> validate_length(:name, max: 100)
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "must be a valid email")
    |> validate_length(:email, max: 254)
    |> unique_constraint(:email, message: "is already on the waitlist")
  end

  def survey_changeset(entry, attrs) do
    entry
    |> cast(attrs, [:name, :child_ages, :worries, :top_priority])
    |> validate_length(:name, max: 100)
  end
end
