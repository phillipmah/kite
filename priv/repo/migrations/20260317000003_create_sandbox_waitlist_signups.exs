defmodule Kite.Repo.Migrations.CreateSandboxWaitlistSignups do
  use Ecto.Migration

  def change do
    create table(:sandbox_waitlist_signups) do
      add :email, :string, null: false
      add :conversation_id, references(:sandbox_conversations, on_delete: :nilify_all)
      add :source, :string, default: "sandbox"

      timestamps(updated_at: false)
    end

    create unique_index(:sandbox_waitlist_signups, [:email])
    create index(:sandbox_waitlist_signups, [:conversation_id])
  end
end
