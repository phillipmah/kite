defmodule Kite.Repo.Migrations.CreateWaitlistEntries do
  use Ecto.Migration

  def change do
    create table(:waitlist_entries) do
      add :name, :string, null: false
      add :email, :string, null: false

      timestamps(updated_at: false)
    end

    create unique_index(:waitlist_entries, [:email])
  end
end
