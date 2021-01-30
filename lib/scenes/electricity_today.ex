defmodule HomeDash.Scene.ElectricityToday do
  use Scenic.Scene

  alias Scenic.Graph
  alias HomeDash.Component.Navigation
  alias HomeDash.Data.Inverter
  alias HomeDash.Data.MetWeather
  alias HomeDash.Data.WeatherIcons
  import Scenic.Primitives
  import HomeDash.Util.Constants

  def init(_, _opts) do
    graph =
      Graph.build(font: :roboto, font_size: 16)
      |> text("Solar", fill: col_3(), text_align: :right, translate: {250, 100})
      |> text("Import", fill: col_3(), text_align: :center, translate: {400, 100})
      |> text("Export", fill: col_3(), text_align: :left, translate: {550, 100})
      |> text("now", fill: col_3(), text_align: :right, translate: {100, 150})
      |> text("today", fill: col_3(), text_align: :right, translate: {100, 200})
      |> text("kW", fill: col_3(), translate: {700, 150})
      |> text("kW/h", fill: col_3(), translate: {700, 200})
      |> text("",
        id: :solar_now,
        fill: col_3(),
        text_align: :right,
        translate: {250, 150},
        font_size: 36
      )
      |> text("",
        id: :solar_today,
        fill: col_3(),
        text_align: :right,
        translate: {250, 200},
        font_size: 36
      )
      |> add_day_graph()
      |> Navigation.add_to_graph({__MODULE__, "Electricity Today", scenes()})

    send(self(), :update)
    {:ok, graph, push: graph}
  end

  defp add_day_graph(graph) do
    # lines indicating kW and placeholders for today's curves
    graph =
      graph
      # |> line({{112, 250},{688, 250}}, stroke: {1, col_1()}) # 4kW
      # 3
      |> line({{112, 275}, {688, 275}}, stroke: {1, col_1()})
      |> text("3.0", text_align: :right, translate: {110, 280}, font_size: 14, fill: col_1())
      # 2.25
      |> line({{112, 287.5}, {688, 287.5}}, stroke: {1, col_1()})
      |> text("2.5", text_align: :right, translate: {110, 292.5}, font_size: 14, fill: col_1())
      # 2
      |> line({{112, 300}, {688, 300}}, stroke: {1, col_1()})
      |> text("2.0", text_align: :right, translate: {110, 305}, font_size: 14, fill: col_1())
      # 1.5
      |> line({{112, 312.5}, {688, 312.5}}, stroke: {1, col_1()})
      |> text("1.5", text_align: :right, translate: {110, 317.5}, font_size: 14, fill: col_1())
      # 1
      |> line({{112, 325}, {688, 325}}, stroke: {1, col_1()})
      |> text("1.0", text_align: :right, translate: {110, 330}, font_size: 14, fill: col_1())
      # 0.5
      |> line({{112, 337.5}, {688, 337.5}}, stroke: {1, col_1()})
      |> text("0.5", text_align: :right, translate: {110, 342.5}, font_size: 14, fill: col_1())
      |> path([], id: :curve_today_body)
      |> path([], id: :curve_today_outline)

    # x-axis
    graph =
      graph
      |> rect({576, 1}, translate: {112, 350}, fill: col_2())

    # hourly ticks
    graph =
      Enum.reduce(0..24, graph, fn h, g ->
        g
        |> rect({1, 5}, translate: {112 + h * 24, 350}, fill: col_2())
      end)

    # hour labels
    graph =
      Enum.reduce([0, 3, 6, 9, 12, 15, 18, 21, 24], graph, fn h, g ->
        g
        |> rect({1, 8}, translate: {112 + h * 24, 350}, fill: col_2())
        |> text(~s"#{h}:00",
          text_align: :center,
          translate: {112 + h * 24, 367},
          fill: col_2(),
          font_size: 12
        )
      end)

    # weather icon, temp
    Enum.reduce(0..23, graph, fn h, g ->
      g
      |> rect({20, 20}, id: {:w_code, h}, translate: {2 + 112 + h * 24, 230})
      |> text("0",
        id: {:w_temp, h},
        text_align: :center,
        translate: {12 + 112 + h * 24, 260},
        font_size: 14,
        fill: col_2()
      )
    end)
  end

  def handle_info(:update, graph) do
    # solar output
    c_watts = 
      case Inverter.get(:current_watts) do
        w when is_integer(w) and w >= 0 -> w
        other ->
          IO.inspect(other, label: "non-numerical current watts ?!?!?!")
          -1
      end

    t_watts = 
      case Inverter.get(:watts_today) do
        w when is_integer(w) and w >= 0 -> w
        other ->
          IO.inspect(other, label: "non-numerical watts today ?!?!?!")
          -1
      end

    current_kW = :io_lib.format("~.2f", [c_watts / 1000.0])
    todays_kWh = :io_lib.format("~.2f", [t_watts / 1000.0])
    # TODO: eliminate duplication above

    graph =
      graph
      |> Graph.modify(:solar_now, fn n -> text(n, ~s"#{current_kW}") end)
      |> Graph.modify(:solar_today, fn n -> text(n, ~s"#{todays_kWh}") end)

    graph =
      case Inverter.get(:series_today) do
        nil ->
          graph

        series ->
          {outline, last_index} =
            series
            |> Enum.with_index()
            |> Enum.reduce({[{:move_to, 0, 100}, :begin], 0}, fn {{_timestamp, watts}, i},
                                                                 {acc, _} ->
              {[{:line_to, i * 2, 100 - watts / 4 * 100} | acc], i}
            end)

          body =
            [:close_path, {:line_to, last_index * 2, 100} | outline]
            |> Enum.reverse()

          outline = Enum.reverse(outline)

          graph
          |> Graph.modify(:curve_today_body, fn primitive ->
            path(primitive, body,
              stroke: {1, col_1()},
              cap: :butt,
              join: :round,
              fill: col_1(),
              translate: {112, 250}
            )
          end)
          |> Graph.modify(:curve_today_outline, fn primitive ->
            path(primitive, outline,
              stroke: {1, col_2()},
              cap: :butt,
              join: :miter,
              translate: {112, 250}
            )
          end)
      end

    # weather
    graph =
      case MetWeather.forecast_for_today() do
        nil ->
          graph

        {:ok, series} ->
          series
          |> Enum.filter(fn
            %{hour: _h, code: _c, temperature: _t} -> true
            _ -> false
          end)
          |> Enum.reduce(graph, fn %{hour: h, code: c, temperature: t}, g ->
            icon_hash = WeatherIcons.get_image_hash(c)

            g
            |> Graph.modify({:w_code, h}, fn p ->
              rect(p, {20, 20}, fill: {:image, {icon_hash, 255}})
            end)
            |> Graph.modify({:w_temp, h}, fn p ->
              text(p, ~s"#{Float.round(1.0 * t) |> Kernel.trunc()}°")
            end)
          end)
      end

    Process.send_after(self(), :update, 100)
    {:noreply, graph, push: graph}
  end
end
