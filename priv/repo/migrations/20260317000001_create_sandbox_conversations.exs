defmodule Kite.Repo.Migrations.CreateSandboxConversations do
  use Ecto.Migration

  def change do
    create table(:sandbox_conversations) do
      add :session_id, :string, null: false
      add :ip_address, :string
      add :model, :string, null: false
      add :child_age, :string, null: false
      add :family_context, :string, null: false
      add :custom_context, :text

      timestamps(updated_at: false)
    end

    create index(:sandbox_conversations, [:session_id])
    create index(:sandbox_conversations, [:ip_address])
    create index(:sandbox_conversations, [:inserted_at])
  end
end
