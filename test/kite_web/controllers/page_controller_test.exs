defmodule KiteWeb.PageControllerTest do
  use KiteWeb.ConnCase

  test "GET / renders waitlist landing page", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "kite"
  end
end
