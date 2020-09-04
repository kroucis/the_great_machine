defmodule TheGreatMachine do
    use GenServer

    def start_link(match_id) do
        GenServer.start_link(__MODULE__, create_match(match_id))
    end

    def init(match) do
        { :ok, match }
    end

    defmodule ControlState do
        @derive Jason.Encoder
        defstruct count: 0, state: 0, visible: false

        def set(%ControlState{} = control, value) do
            %{ control | count: value }
        end

        def increment(%ControlState{count: count} = control) do
            set control, count + 1
        end

        def decrement(%ControlState{count: count} = control) do
            set control, count - 1
        end

        def make_visible(%ControlState{} = control) do
            %{ control | visible: true }
        end

        def make_hidden(%ControlState{} = control) do
            %{ control | visible: false }
        end

        def check(%ControlState{visible: false}, _) do
            false
        end
        def check(%ControlState{count: count, visible: true}, minVal) do
            count >= minVal
        end
        def check(%ControlState{count: count, visible: true}, minVal, maxVal) do
            count >= minVal and count <= maxVal
        end

    end

    defmodule Machine do
        @derive Jason.Encoder
        defstruct blue_button: %ControlState{visible: true},
            red_button: %ControlState{},
            green_button: %ControlState{count: 1},
            button_array: %ControlState{state: -1},
            wheel: %ControlState{count: 1},
            guess: %ControlState{state: -1},
            dial_pad: %ControlState{state: -1},
            unlock: %ControlState{}

    end

    defmodule Player do
        @derive {Jason.Encoder, only: [:id]}
        defstruct id: 0, data: nil
    end

    defmodule Match do
        @derive {Jason.Encoder, only: [:id, :machine]}
        defstruct id: 0, players: %{}, next_player_id: 0, machine: %Machine{}, phase: TheGreatMachine.Phase0
    end

    def create_match(match_id) when is_number(match_id) do
        %Match{id: match_id}
    end

    defp create_player(player_id, player_data) do
        %Player{id: player_id, data: player_data}
    end

    def get_match(pid) do
        GenServer.call(pid, :get_match)
    end

    def get_players(pid) do
        GenServer.call(pid, :get_players)
    end

    def add_player(pid, player_data) do
        GenServer.call(pid, {:add_player, player_data})
    end

    def remove_player(pid, player_id) do
        GenServer.call(pid, {:remove_player, player_id})
    end

    def perform(pid, player_data, action, data) do
        GenServer.call(pid, {:perform, player_data, action, data})
    end

    def handle_call(:get_match, _from, state) do
        {:reply, {:ok, state}, state}
    end

    def handle_call(:get_players, _from, state) do
        {:reply, {:ok, state.players}, state}
    end

    def handle_call({:add_player, player_data}, _from, state) do
        player_id = state.next_player_id
        new_players = Map.put(state.players, player_id, create_player(player_id, player_data))
        {:reply, {:ok, player_id}, %{state | players: new_players, next_player_id: state.next_player_id + 1}}
    end

    def handle_call({:remove_player, player_id}, _from, state) do
        new_players = Map.delete(state.players, player_id)
        {:reply, :ok, %{state | players: new_players}}
    end

    def handle_call({:perform, player_id, action, data}, _from, state) do
        player = state.players[player_id]
        case state.phase.perform(player, action, data, state.machine) do
            %Machine{} = machine ->
                # IO.puts state.phase
                case state.phase.check(machine) do
                    %Machine{} = machine ->
                        {:reply, {:ok, machine}, %{state | machine: machine}}
                    { %Machine{} = machine, phase } ->
                        {:reply, {:ok, machine}, %{state | machine: machine, phase: phase}}
                end
            { %Machine{} = machine, phase } ->
                {:reply, {:ok, machine}, %{state | machine: machine, phase: phase}}
            nil ->
                {:reply, :error, state}
        end
    end

end

defmodule TheGreatMachine.Phase do
    alias TheGreatMachine.ControlState
    alias TheGreatMachine.Machine
    alias TheGreatMachine.Player

    def phase(step) do
        quote do
            alias TheGreatMachine.ControlState
            alias TheGreatMachine.Machine
            alias TheGreatMachine.Player

            @blue_cost ((:math.pow(2, unquote(step)) |> round) * 60) |> round
            @red_cost (@blue_cost / 4 |> round)

            IO.inspect @blue_cost

            def check(nil) do
                nil
            end
        end
    end

    defmacro __using__(step: step) when is_number(step) do
        apply(__MODULE__, :phase, [step])
    end

    defmacro __using__(_) do
       apply(__MODULE__, :phase, [0])
    end
end

defmodule TheGreatMachine.Phase0 do
    use TheGreatMachine.Phase

    def perform(%Player{} = _, "blue_button", nil, %Machine{} = machine) do
        blue_total = machine.blue_button.count + machine.green_button.count - (((machine.button_array.state != -1) && 1 || 0) + ((machine.guess.state != -1) && 1 || 0) + ((machine.dial_pad.state != -1) && 1 || 0))
        %{ machine | blue_button: ControlState.set(machine.blue_button, blue_total) }
    end

    def perform(_, _, _, _) do
        nil
    end

    def check(%Machine{} = machine) do
        if ControlState.check machine.blue_button, 5 do
            machine = %{ machine | red_button: ControlState.make_visible machine.red_button }
            { machine, TheGreatMachine.Phase1 }
        else
            machine
        end
    end

end

defmodule TheGreatMachine.Phase1 do
    use TheGreatMachine.Phase

    def perform(%Player{} = _, "red_button", nil,  %Machine{} = machine) do
        %{ machine | red_button: ControlState.increment machine.red_button }
    end

    defdelegate perform(player, action, data, machine), to: TheGreatMachine.Phase0

    def check(%Machine{blue_button: %ControlState{count: blue_count}, red_button: %ControlState{count: red_count}} = machine) when blue_count >= 10 and red_count >= 8 do
        machine = %{ machine | green_button: ControlState.make_visible machine.green_button }
        { machine, TheGreatMachine.Phase2 }
    end

    def check(%Machine{} = machine) do
        machine
    end

end

defmodule TheGreatMachine.Phase2 do
    use TheGreatMachine.Phase

    def perform(%Player{} = _, "green_button", nil,  %Machine{} = machine) do
        red_cost = 4 * (:math.pow(2, machine.green_button.count) |> round)
        if machine.red_button.count >= red_cost do
            machine = %{ machine | red_button: ControlState.set(machine.red_button, machine.red_button.count - red_cost) }
            machine = %{ machine | green_button: ControlState.increment machine.green_button }
            machine
        else
            machine
        end
    end

    defdelegate perform(player, action, data, machine), to: TheGreatMachine.Phase1

    def check(%Machine{blue_button: %ControlState{count: blue_count}} = machine) when blue_count >= @blue_cost do
        machine = %{ machine | unlock: ControlState.make_visible(machine.unlock) |> ControlState.set(@blue_cost) }
        { machine, TheGreatMachine.Phase3 }
    end

    def check(%Machine{} = machine) do
        machine
    end

end

defmodule TheGreatMachine.Phase3 do
    use TheGreatMachine.Phase

    def perform(%Player{} = _, "unlock", %{"value" => _value}, %Machine{blue_button: %ControlState{count: blue_count}, unlock: %ControlState{state: 0, visible: true}} = machine) when blue_count >= @blue_cost do
         machine = %{ machine | blue_button: ControlState.set(machine.blue_button, machine.blue_button.count - @blue_cost) }
        machine = %{ machine | unlock: ControlState.make_hidden machine.unlock }
        machine = %{ machine | button_array: ControlState.make_visible machine.button_array }
        { machine, TheGreatMachine.Phase4 }
    end

    # def perform(%Player{} = _, "unlock", %{"value" => value}, %Machine{unlock: %ControlState{state: 0, visible: true}} = machine) do
    #     blue_cost = @blue_cost
    #     if value == blue_cost and machine.blue_button.count >= blue_cost do
    #         machine = %{ machine | blue_button: ControlState.set(machine.blue_button, machine.blue_button.count - blue_cost) }
    #         machine = %{ machine | unlock: ControlState.make_hidden machine.unlock }
    #         machine = %{ machine | button_array: ControlState.make_visible machine.button_array }
    #         { machine, TheGreatMachine.Phase4 }
    #     else
    #         machine
    #     end
    # end

    defdelegate perform(player, action, data, machine), to: TheGreatMachine.Phase2

    def check(%Machine{} = machine) do
        machine
    end

end

defmodule TheGreatMachine.Phase4 do
    use TheGreatMachine.Phase, step: 1

    def perform(%Player{} = _, "button_array", %{"value" => 0}, %Machine{button_array: %ControlState{state: -1}} = machine) do
        %{ machine | button_array: %{ machine.button_array | state: 1 } }
    end

    def perform(%Player{} = _, "button_array", %{"value" => -1}, %Machine{} = machine) do
        %{ machine | button_array: %{ machine.button_array | state: -1 } }
    end

    def perform(%Player{} = _, "button_array", %{"value" => value}, %Machine{blue_button: %ControlState{count: blue_count}} = machine) when blue_count > 0 do
        value =
            value
            |> max(1)
            |> min(3)
        { new_state, did_cycle } =
            case { machine.button_array.state, value } do
                { -3, 2 } ->
                    { -2, false }
                { -3, 3 } ->
                    { -3, false }
                { -2, 2 } ->
                    { -2, false }
                { -2, -3 } ->
                    { -3, false }
                { 1, 2 } ->
                    { 2, false }
                { 1, 3 } ->
                    { -3, false }
                { 2, 2 } ->
                    { 2, false }
                { 2, 3 } ->
                    { 3, false }
                { 3, 2 } ->
                    { 4, false }
                { 3, 3 } ->
                    { 3, false }
                { 4, 1 } ->
                    { 1, true }
                { 4, 2 } ->
                    { 4, false }
                { 4, 3 } ->
                    { -3, false }
                { _, 1 } ->
                    { 1, false }
                _ ->
                    { 1, false }
            end
        blue_cost = (did_cycle && 1 || 0)
        new_blue = %{ machine.blue_button | count: machine.blue_button.count - blue_cost }
        new_button_array = %ControlState{count: machine.button_array.count + (did_cycle && 1 || 0), state: new_state, visible: true }
        %{ machine | blue_button: new_blue, button_array: new_button_array }
    end

    def perform(%Player{} = _, "engage", nil, %Machine{button_array: %ControlState{count: button_array_count}} = machine) when button_array_count >= 15 do
        engage_cost = 5 + :rand.uniform(10)
        blue_generated = round(engage_cost * 1.5) * 15
        new_button_array = %{ machine.button_array | count: machine.button_array.count - engage_cost }
        new_blue = %{machine.blue_button | count: machine.blue_button.count + blue_generated}
        %{ machine | blue_button: new_blue, button_array: new_button_array }
    end

    defdelegate perform(player, action, data, machine), to: TheGreatMachine.Phase3

    def check(%Machine{blue_button: %ControlState{count: blue_count}, red_button: %ControlState{count: red_count}} = machine) when blue_count >= @blue_cost and red_count >= @red_cost do
        { %{ machine | unlock: %ControlState{count: @blue_cost, state: 1, visible: true} }, TheGreatMachine.Phase5 }
    end

    def check(%Machine{} = machine) do
        machine
    end

end

defmodule TheGreatMachine.Phase5 do
    use TheGreatMachine.Phase, step: 1

    def perform(%Player{} = _, "unlock", %{"value" => _value}, %Machine{blue_button: %ControlState{count: blue_count}, red_button: %ControlState{count: red_count}, unlock: %ControlState{state: 1, visible: true}} = machine) when blue_count >= @blue_cost and red_count >= @red_cost do
        machine = %{ machine | blue_button: ControlState.set(machine.blue_button, machine.blue_button.count - @blue_cost) }
        machine = %{ machine | red_button: ControlState.set(machine.red_button, machine.red_button.count - @red_cost) }
        machine = %{ machine | unlock: ControlState.make_hidden machine.unlock }
        machine = %{ machine | wheel: ControlState.make_visible machine.wheel }
        { machine, TheGreatMachine.Phase6 }
    end

    defdelegate perform(player, action, data, machine), to: TheGreatMachine.Phase4

    def check(%Machine{} = machine) do
        machine
    end

end

defmodule TheGreatMachine.Phase6 do
    use TheGreatMachine.Phase, step: 2

    def perform(%Player{} = _, "wheel", %{"value" => value}, %Machine{blue_button: %ControlState{count: blue_count}} = machine) when blue_count > 0 do
        value =
            value
            |> max(0)
            |> min(7)
        { new_state, did_cycle } =
            case { machine.wheel.state, value } do
                { 7, 0 } ->
                    { 0, true }
                { x, y } when y == x + 1 ->
                    { x + 1, false }
                { x, _ } ->
                    { x, false }
            end
        blue_cost = (did_cycle && 1 || 0)
        new_blue = %{ machine.blue_button | count: machine.blue_button.count - blue_cost }
        new_wheel = %{ machine.wheel | state: new_state }
        new_button_array = %{ machine.button_array | count: machine.button_array.count + (did_cycle && machine.wheel.count || 0) }
        %{ machine | blue_button: new_blue, button_array: new_button_array, wheel: new_wheel }
    end

    defdelegate perform(player, action, data, machine), to: TheGreatMachine.Phase5

    def check(%Machine{blue_button: %ControlState{count: blue_count}, red_button: %ControlState{count: red_count}} = machine) when blue_count >= @blue_cost and red_count >= @red_cost do
        { %{ machine | unlock: %ControlState{count: @blue_cost, state: 2, visible: true} }, TheGreatMachine.Phase7 }
    end

    def check(%Machine{} = machine) do
        machine
    end

end

defmodule TheGreatMachine.Phase7 do
    use TheGreatMachine.Phase, step: 2

    def perform(%Player{} = _, "unlock", %{"value" => _value}, %Machine{blue_button: %ControlState{count: blue_count}, red_button: %ControlState{count: red_count}, unlock: %ControlState{state: 2, visible: true}} = machine) when blue_count >= @blue_cost and red_count >= @red_cost do
        machine = %{ machine | blue_button: ControlState.set(machine.blue_button, machine.blue_button.count - @blue_cost) }
        machine = %{ machine | red_button: ControlState.set(machine.red_button, machine.red_button.count - @red_cost) }
        machine = %{ machine | unlock: ControlState.make_hidden machine.unlock }
        machine = %{ machine | guess: ControlState.make_visible machine.guess }
        { machine, TheGreatMachine.Phase8 }
    end

    defdelegate perform(player, action, data, machine), to: TheGreatMachine.Phase6

    def check(%Machine{} = machine) do
        machine
    end

end

defmodule TheGreatMachine.Phase8 do
    use Bitwise, only_operators: true
    use TheGreatMachine.Phase, step: 3

    def perform(%Player{} = _, "guess", %{"value" => 0}, %Machine{guess: %ControlState{state: -1}} = machine) do
        %{ machine | guess: %{ machine.guess | state: :rand.uniform(8) + 1, count: 0 } }
    end

    def perform(%Player{} = _, "guess", %{"value" => -1}, %Machine{} = machine) do
        %{ machine | guess: %{ machine.button_array | state: -1 } }
    end

    def perform(%Player{} = _, "guess", %{"value" => value}, %Machine{blue_button: %ControlState{count: blue_count}} = machine) when blue_count > 0 do
        num = :math.pow(2, value - 1) |> round
        blue_cost = 1
        cond do
            value == machine.guess.state ->
                blue_generated = machine.guess.state * 5
                machine = %{ machine | blue_button: ControlState.set(machine.blue_button, machine.blue_button.count + (blue_generated - blue_cost)) }
                machine = %{ machine | guess: %{ machine.guess | state: :rand.uniform(8) + 1, count: 0 } }
                machine
            (num &&& machine.guess.count) == num ->
                machine
            true ->
                new_blue = %{ machine.blue_button | count: machine.blue_button.count - blue_cost }
                %{ machine | blue_button: new_blue, guess: %{ machine.guess | count: machine.guess.count + num } }
        end
    end

    defdelegate perform(player, action, data, machine), to: TheGreatMachine.Phase7

    def check(%Machine{blue_button: %ControlState{count: blue_count}, red_button: %ControlState{count: red_count}} = machine) when blue_count >= @blue_cost and red_count >= @red_cost do
        { %{ machine | unlock: %ControlState{count: @blue_cost, state: 3, visible: true} }, TheGreatMachine.Phase9 }
    end

    def check(%Machine{} = machine) do
        machine
    end

end

defmodule TheGreatMachine.Phase9 do
    use TheGreatMachine.Phase, step: 3

    def perform(%Player{} = _, "unlock", %{"value" => _value}, %Machine{blue_button: %ControlState{count: blue_count}, red_button: %ControlState{count: red_count}, unlock: %ControlState{state: 3, visible: true}} = machine) when blue_count >= @blue_cost and red_count >= @red_cost do
        machine = %{ machine | blue_button: ControlState.set(machine.blue_button, machine.blue_button.count - @blue_cost) }
            machine = %{ machine | red_button: ControlState.set(machine.red_button, machine.red_button.count - @red_cost) }
            machine = %{ machine | unlock: ControlState.make_hidden machine.unlock }
            machine = %{ machine | dial_pad: ControlState.make_visible machine.dial_pad }
            { machine, TheGreatMachine.Phase10 }
    end

    defdelegate perform(player, action, data, machine), to: TheGreatMachine.Phase8

    def check(%Machine{} = machine) do
        machine
    end

end

defmodule TheGreatMachine.Phase10 do
    use TheGreatMachine.Phase, step: 4

    def perform(%Player{} = _, "dial_pad", %{"value" => 0}, %Machine{dial_pad: %ControlState{state: -1}} = machine) do
        %{ machine | dial_pad: %{ machine.dial_pad | state: :rand.uniform(9_999), count: 0 } }
    end

    def perform(%Player{} = _, "dial_pad", %{"value" => _value}, %Machine{dial_pad: %ControlState{state: -1}} = machine) do
        machine
    end

    def perform(%Player{} = _, "dial_pad", %{"value" => -1}, %Machine{} = machine) do
        %{ machine | dial_pad: %{ machine.dial_pad | state: -1 } }
    end

    def perform(%Player{} = _, "dial_pad", %{"value" => value}, %Machine{} = machine) do
        value =
            value
                |> max(0)
                |> min(9_999)
        if value == machine.dial_pad.state do
            blue_generated = 200
            machine = %{ machine | blue_button: ControlState.set(machine.blue_button, machine.blue_button.count + blue_generated) }
            machine = %{ machine | dial_pad: %{ machine.dial_pad | state: :rand.uniform(9_999) } }
            machine
        else
            %{ machine | dial_pad: %{ machine.dial_pad | count: value } }
        end
    end

    defdelegate perform(player, action, data, machine), to: TheGreatMachine.Phase9

    def check(%Machine{blue_button: %ControlState{count: blue_count}, red_button: %ControlState{count: red_count}} = machine) when blue_count >= @blue_cost and red_count >= @red_cost do
        { %{ machine | unlock: %ControlState{count: @blue_cost, state: 4, visible: true} }, TheGreatMachine.Phase11 }
    end

    def check(%Machine{} = machine) do
        machine
    end

end

defmodule TheGreatMachine.Phase11 do
    use TheGreatMachine.Phase, step: 4

    def perform(%Player{} = _, "unlock", %{"value" => _value}, %Machine{blue_button: %ControlState{count: blue_count}, red_button: %ControlState{count: red_count}, unlock: %ControlState{state: 4, visible: true}} = machine) when blue_count >= @blue_cost and red_count >= @red_cost do
        machine = %{ machine | blue_button: ControlState.set(machine.blue_button, machine.blue_button.count - @blue_cost) }
        machine = %{ machine | red_button: ControlState.set(machine.red_button, machine.red_button.count - @red_cost) }
        machine = %{ machine | unlock: ControlState.make_hidden machine.unlock }
        machine = %{ machine | wheel: ControlState.increment machine.wheel }
        { machine, TheGreatMachine.Phase12 }
    end

    defdelegate perform(player, action, data, machine), to: TheGreatMachine.Phase10

    def check(%Machine{} = machine) do
        machine
    end

end

defmodule TheGreatMachine.Phase12 do
    use TheGreatMachine.Phase, step: 5

    def perform(%Player{} = _, "wheel_amp", %{"value" => _value}, %Machine{blue_button: %ControlState{count: blue_count}, wheel: %ControlState{count: wheel_count}} = machine) do
        blue_cost = :math.pow(2, wheel_count + 1) * 200
        if blue_count <= blue_cost do
            machine = %{ machine | blue_button: ControlState.set(machine.blue_button, machine.blue_button.count - blue_cost) }
            machine = %{ machine | wheel: ControlState.increment machine.wheel}
            machine
        else
            machine
        end
    end

    defdelegate perform(player, action, data, machine), to: TheGreatMachine.Phase11

    def check(%Machine{} = machine) do
        machine
    end

end
