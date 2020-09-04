defmodule TheGreatMachineWeb.MatchChannel do
  use TheGreatMachineWeb, :channel

  def join("match:" <> match_id_str, _payload, socket) do
    {match_id, ""} = Integer.parse(match_id_str)
    case TheGreatMachine.Matchmaker.get_match_instance(match_id) do
      {:ok, _match_pid} ->
        {:ok, assign(socket, :match_id, match_id)}
      _ ->
        case TheGreatMachine.Matchmaker.start_match(match_id) do
          :ok ->
            {:ok, assign(socket, :match_id, match_id)}
          _ ->
            {:error, socket}
        end
    end
  end

  def handle_in("join", _payload, socket) do
    match_id = socket.assigns[:match_id]
    case TheGreatMachine.Matchmaker.get_match_instance(match_id) do
      {:ok, match_pid} ->
        {:ok, player_id} = TheGreatMachine.add_player(match_pid, %{socket: socket})
        {:ok, match_state} = TheGreatMachine.get_match(match_pid)
        send "sync.player_count", %{player_count: match_state.player_count}, socket
        ok %{match: match_state, player: %{id: player_id}}, assign(socket, :player_id, player_id)
      _ ->
        error "No match with id #{match_id}", socket
    end
  end

  def handle_in("perform", payload, socket) do
    match_id = socket.assigns[:match_id]
    player_id = socket.assigns[:player_id]
    case TheGreatMachine.Matchmaker.get_match_instance(match_id) do
      {:ok, match_pid} ->
        action = Map.get(payload, "action")
        data = Map.get(payload, "data")
        case TheGreatMachine.perform match_pid, player_id, action, data do
          {:ok, machine_state} ->
            send "sync.machine", machine_state, socket
            ok %{}, socket
          :error ->
            error "Cannot perform '#{action}' with '#{Jason.encode! payload}'", socket
        end

      _ ->
        error "No match with id #{match_id}", socket
    end
  end

  def terminate(_reason, socket) do
    match_id = socket.assigns[:match_id]
    player_id = socket.assigns[:player_id]
    case TheGreatMachine.Matchmaker.get_match_instance(match_id) do
      {:ok, match_pid} ->
        {:ok, players} = TheGreatMachine.remove_player(match_pid, player_id)
        send "sync.player_count", %{player_count: Enum.count(players)}, socket
      _ ->
        nil
    end
  end

  defp ok(payload, socket) do
    {:reply, {:ok, %{data: payload}}, socket}
  end

  defp error(reason, socket) do
    {:reply, {:error, %{data: reason}}, socket}
  end

  defp send(event, payload, socket) do
    broadcast! socket, event, %{data: payload}
  end

end
