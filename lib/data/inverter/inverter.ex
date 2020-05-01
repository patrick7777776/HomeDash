defmodule HomeDash.Data.Inverter do
  use GenServer

  @name __MODULE__
  @table :inverter_db

  def init(_) do
    Process.flag(:trap_exit, true)
    :ets.new(@table, [:named_table, :set, :protected, read_concurrency: true])
    {:ok, nil}
  end

  def handle_cast({:store, tag, data}, state) do
    :ets.insert(@table, {tag, data})
    {:noreply, state}
  end

  def handle_call({:get, tag}, _from, state) do
    result =
      case :ets.lookup(@table, tag) do
        [] -> nil
        [{^tag, r}] -> r
      end

    {:reply, result, state}
  end

  def start_link(args), do: GenServer.start_link(@name, args, name: @name)

  def get(tag), do: GenServer.call(@name, {:get, tag})
  def update(tag, value), do: GenServer.cast(@name, {:store, tag, value})
end
