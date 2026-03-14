defmodule PhoenixStarterWeb.PageController do
  use PhoenixStarterWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
