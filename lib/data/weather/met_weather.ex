defmodule HomeDash.Data.MetWeather do
  import Ex2ms
  use GenServer

  @name __MODULE__
  @table :met_weather_db
  @initial_reap_delay 30 * 1000
  @reap_interval 12 * 60 * 60 * 1000

  def init(_) do
    Process.flag(:trap_exit, true)
    Process.send_after(self(), :reap, @initial_reap_delay)
    {:ok, nil, {:continue, :met_weather_db}}
  end

  def handle_continue(:met_weather_db, state) do
    {:ok, _dets} = :dets.open_file(@table, file: 'priv/met_weather.dets', type: :set)
    {:noreply, state}
  end

  def handle_cast({:store, hourly_forecasts}, state) do
    records =
      hourly_forecasts
      |> Enum.map(fn hourly_forecast ->
        {Map.get(hourly_forecast, :timestamp), hourly_forecast}
      end)

    :dets.insert(@table, records)
    {:noreply, state}
  end

  def handle_call(:get_today, _from, state) do
    now = Timex.now()

    beginning_of_today =
      now
      |> Timex.beginning_of_day()
      |> Timex.to_unix()

    end_of_today =
      now
      |> Timex.end_of_day()
      |> Timex.to_unix()

    ms =
      fun do
        {timestamp, obj} when timestamp >= ^beginning_of_today and timestamp <= ^end_of_today ->
          obj
      end

    result =
      case :dets.select(@table, ms) do
        {:error, _reason} = err -> err
        hourlies when is_list(hourlies) -> {:ok, hourlies}
      end

    {:reply, result, state}
  end

  def handle_info(:reap, state) do
    end_of_yesterday =
      Timex.now()
      |> Timex.shift(days: -1)
      |> Timex.end_of_day()
      |> Timex.to_unix()

    ms =
      fun do
        {timestamp, _} = obj when timestamp <= ^end_of_yesterday -> true
      end

    :dets.match_delete(@table, ms)
    Process.send_after(self(), :reap, @reap_interval)
    {:noreply, state}
  end

  def terminate(_reason, _state) do
    :dets.close(@table)
  end

  def start_link(args) do
    GenServer.start_link(@name, args, name: @name)
  end

  def forecast_for_today() do
    GenServer.call(@name, :get_today)
  end

  def update_forecasts(hourly_forecasts) do
    GenServer.cast(@name, {:store, hourly_forecasts})
  end
end
