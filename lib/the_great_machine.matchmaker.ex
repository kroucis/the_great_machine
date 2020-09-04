defmodule TheGreatMachine.Matchmaker do
    use GenServer

    def start_link(_args) do
        GenServer.start_link(__MODULE__, nil, name: __MODULE__)
    end

    def init(_args) do
        {:ok, %{ }}
    end

    def start_match(match_id) when is_number(match_id) do
        GenServer.call(__MODULE__, {:start_match, match_id})
    end

    def get_match_instance(match_id) when is_number(match_id) do
        GenServer.call(__MODULE__, {:get_match_instance, match_id})
    end

    def handle_call({:start_match, match_id}, _from, state) do
        {:ok, pid} = TheGreatMachine.start_link(match_id)
        {:reply, :ok, Map.put(state, match_id, pid)}
    end

    def handle_call({:get_match_instance, match_id}, _from, state) do
        case Map.get(state, match_id) do
            nil ->
                {:reply, :error, state}
            pid ->
                {:reply, {:ok, pid}, state}
        end
    end

end
