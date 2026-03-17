defmodule Kite.Repo.Migrations.CreateSandboxMessages do
  use Ecto.Migration

  def change do
    create table(:sandbox_messages) do
      add :conversation_id, references(:sandbox_conversations, on_delete: :delete_all),
        null: false

      add :role, :string, null: false
      add :content, :text, null: false
      add :latency_ms, :integer

      timestamps(updated_at: false)
    end

    create index(:sandbox_messages, [:conversation_id])
  end
end
