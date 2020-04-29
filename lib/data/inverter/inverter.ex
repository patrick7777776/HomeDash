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

  # def start_link(args), do: GenServer.start_link(@name, args, name: @name)
  def start_link(args), do: GenServer.start_link(@name, args, name: @name)

  # def device_info(), do: GenServer.call(@name, {:get, :device_info})
  # def health_status(), do: GenServer.call(@name, {:get, :health_status})
  # def total_yield(), do: GenServer.call(@name,  {:get, :total_yield})
  # def current_kw(), do: GenServer.call(@name,  {:get, :current_kw})
  # def kwh_today(), do: GenServer.call(@name,  {:get, :kwh_today})
  # def kwh_today_curve(), do: GenServer.call(@name,  {:get, :kwh_today_curve})

  def get(tag), do: GenServer.call(@name, {:get, tag})
  def update(tag, value), do: GenServer.cast(@name, {:store, tag, value})
  # def set_device_info(info), do: GenServer.cast(@name, {:store, :device_info, info})
  # def set_health_status(status), do: GenServer.cast(@name, {:store, :health_status, status})
  # def set_total_yield(total_yield), do: GenServer.cast(@name, {:store, :total_yield, total_yield})
  # def set_current_kw(current_kw), do: GenServer.call(@name,  {:store, :current_kw, current_kw})
  # def set_kwh_today(kwh_today), do: GenServer.call(@name,  {:store, :kwh_today, kwh_today})
  # def set_kwh_today_curve(kwh_today_curve), do: GenServer.call(@name,  {:store, :kwh_today_curve, kwh_today_curve})
end
