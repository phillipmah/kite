defmodule KiteWeb.PageController do
  use KiteWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
