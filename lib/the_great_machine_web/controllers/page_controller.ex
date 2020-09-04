defmodule TheGreatMachineWeb.PageController do
  use TheGreatMachineWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
