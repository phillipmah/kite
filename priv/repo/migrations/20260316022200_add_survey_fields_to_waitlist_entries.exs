defmodule Kite.Repo.Migrations.AddSurveyFieldsToWaitlistEntries do
  use Ecto.Migration

  def change do
    alter table(:waitlist_entries) do
      modify :name, :string, null: true, from: {:string, null: false}
      add :child_ages, {:array, :string}, default: []
      add :worries, {:array, :string}, default: []
      add :top_priority, :string
    end
  end
end
