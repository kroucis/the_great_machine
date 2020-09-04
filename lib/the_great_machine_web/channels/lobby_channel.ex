defmodule TheGreatMachineWeb.LobbyChannel do
  use TheGreatMachineWeb, :channel

  def join("lobby:lobby", payload, socket) do
    {:ok, socket}
  end

  def match_state(match) do
    %{ id: match.id
     }
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  # def handle_in("ready", _payload, socket) do
  #   match_id = :rand.uniform(1000000)
  #   {:ok, server} = TheGreatMachine.start(match_id, [socket])
  #   match = TheGreatMachine.get_match(server)
  #   socket = assign(socket, :match_id, match.id)
  #   reply = %{ id: :rand.uniform(10000),
  #              match: match_state(match)
  #            }
  #   {:reply, {:ok, reply}, socket}
  # end

end
