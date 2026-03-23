defmodule Kite.Waitlist do
  alias Kite.Repo
  alias Kite.Waitlist.Entry

  def change_entry(%Entry{} = entry, attrs \\ %{}) do
    Entry.changeset(entry, attrs)
  end

  def join_waitlist(attrs) do
    %Entry{}
    |> Entry.changeset(attrs)
    |> Repo.insert()
  end

  def get_entry!(id), do: Repo.get!(Entry, id)

  def update_survey(%Entry{} = entry, attrs) do
    entry
    |> Entry.survey_changeset(attrs)
    |> Repo.update()
  end
end
