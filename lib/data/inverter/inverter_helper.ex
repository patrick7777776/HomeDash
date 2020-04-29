defmodule HomeDash.Data.InverterHelper do
  # TODO: Needs tidying up!

  def last_n_days_raw(session, n, type \\ :daily) do
    base =
      Timex.now()
      |> Timex.beginning_of_day()

    t1 =
      base
      |> Timex.shift(days: -n, hours: -2)
      |> Timex.to_unix()

    t2 =
      base
      |> Timex.shift(hours: 2)
      |> Timex.to_unix()

    if type == :daily do
      QSB36.yield_daily(session, t1, t2)
    else
      QSB36.yield_5min(session, t1, t2)
    end
  end

  def last_n_days(session, n) do
    case last_n_days_raw(session, n) do
      {:ok, yields} when length(yields) == n + 1 ->
        yields
        |> Enum.reduce({nil, []}, fn
          {_, w}, {nil, []} -> {w, []}
          {_, w}, {pw, acc} -> {w, [w - pw | acc]}
        end)
        |> elem(1)
        |> Enum.reverse()

      _ ->
        nil
    end
  end

  def today_so_far(session) do
    with {:ok, [_, {_, yesterdays_total} | _]} = last_n_days_raw(session, 1),
         {:ok, total} = QSB36.total_yield(session) do
      {:ok, total - yesterdays_total}
    else
      err -> err
    end
  end

  # time series cumulative yield so far today
  def today_so_far_5min(session) do
    ti = Timex.timezone("Europe/London", Timex.now())
    offset_hours = -1 * trunc(ti.offset_std / 3600)
    #qsb_info = QSB36.current_time(session)

    now = Timex.now()

    begin =
      now
      |> Timex.beginning_of_day()
      |> Timex.shift(hours: offset_hours)
      |> Timex.to_unix()

    s =
      now
      |> Timex.beginning_of_day()
      |> Timex.shift(hours: -2)
      |> Timex.to_unix()

    e =
      now
      |> Timex.to_unix()


    with {:ok, [_, {_, yesterdays_total} | _]} = last_n_days_raw(session, 1),
         {:ok, vals} = QSB36.yield_5min(session, s, e) do
      # TODO: drop anything that is before 0am in our timezone
      vals = Enum.drop_while(vals, fn {ts, _} -> ts < begin end)

      [_x | _] = vals

      {cvals, _} =
        vals
        |> Enum.reduce({[], yesterdays_total}, fn {timestamp, val}, {acc, p} ->
          {[{timestamp, (val - p) / 1000 / 0.0833333} | acc], val}
        end)

      {:ok, Enum.reverse(cvals)}
    else
      err -> err
    end
  end
end
