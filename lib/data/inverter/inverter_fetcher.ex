defmodule HomeDash.Data.InverterFetcher do
  use GenServer
  require Logger
  alias HomeDash.Data.Inverter
  alias HomeDash.Data.InverterHelper

  @cool_off 5 * 1000
  @tasks %{
    device_info: {&QSB36.device_info/1, 60 * 60 * 1000},
    health_status: {&QSB36.health_status/1, 2 * 60 * 1000},
    total_watts: {&QSB36.total_yield/1, 5 * 60 * 1000},
    current_watts: {&QSB36.current_watts/1, 1 * 1000},
    watts_today: {&InverterHelper.today_so_far/1, 5 * 1000},
    series_today: {&InverterHelper.today_so_far_5min/1, 5 * 60 * 1000}
  }

  def init(_) do
    Process.flag(:trap_exit, true)
    schedule(Map.keys(@tasks))

    {:ok,
     {Application.get_env(:home_dash, :inverter_ip),
      Application.get_env(:home_dash, :inverter_secret), nil}}
  end

  def handle_info(tag, {host, pw, session} = _state) do
    case Map.get(@tasks, tag, nil) do
      nil ->
        :ignore

      {fun, interval} ->
        with {:ok, s} <- ensure_logged_in(host, pw, session) do
          with {:ok, value} <- fun.(s) do
            Inverter.update(tag, value)
            schedule(tag, interval)
            {:noreply, {host, pw, s}}
          else
            err ->
              Logger.warn(~s"Inverter fetcher: #{inspect(err)} ; scheduling retry...")
              reschedule(tag, host, pw, s)
          end
        else
          err ->
            Logger.warn(~s"Inverter fetcher: #{inspect(err)} ; scheduling retry...")
            reschedule(tag, host, pw, session)
        end
    end
  end

  defp reschedule(tag, host, pw, session) do
    ensure_logged_out(session)
    schedule(tag, @cool_off)
    {:noreply, {host, pw, nil}}
  end

  def terminate(_reason, {_, _, session}), do: ensure_logged_out(session)

  defp schedule(many) when is_list(many), do: Enum.each(many, fn type -> schedule(type, 100) end)

  defp schedule(type, millis), do: Process.send_after(self(), type, millis)

  defp ensure_logged_in(host, pw, nil), do: QSB36.user_login(host, pw)

  defp ensure_logged_in(_host, _pw, session), do: {:ok, session}

  defp ensure_logged_out(nil), do: :ok

  defp ensure_logged_out(session), do: QSB36.logout(session)

  def start_link(args), do: GenServer.start_link(__MODULE__, args, name: __MODULE__)
end
