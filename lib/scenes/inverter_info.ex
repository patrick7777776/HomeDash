defmodule HomeDash.Scene.InverterInfo do
  use Scenic.Scene

  alias Scenic.Graph
  alias HomeDash.Component.Navigation
  alias HomeDash.Data.Inverter
  import Scenic.Primitives
  import HomeDash.Util.Constants, only: [scenes: 0, col_3: 0]

  def init(_, _opts) do
    graph =
      Graph.build(font: :roboto, font_size: 24, fill: col_3())
      |> text("Model:", translate: {30, 100})
      |> text("", id: :model, translate: {300, 100})
      |> text("Serial no:", translate: {30, 130})
      |> text("", id: :serial, translate: {300, 130})
      |> text("Total yield to date:", translate: {30, 160})
      |> text("", id: :total, translate: {300, 160})
      |> text("Operational health status:", translate: {30, 190})
      |> text("", id: :health, translate: {300, 190})
      |> Navigation.add_to_graph({__MODULE__, "Inverter Info", scenes()})

    send(self(), :update)
    {:ok, graph, push: graph}
  end

  def handle_info(:update, graph) do
    {model, serial} =
      case Inverter.get(:device_info) do
        nil -> {"...", "..."}
        {_m, _s} = ms -> ms
      end

    {health_code, health_name} =
      case Inverter.get(:health_status) do
        nil -> {-1, nil}
        {_c, _n} = cn -> cn
      end

    totalkWh =
      ((Inverter.get(:total_watts) || 0) / 1000.0)
      |> Float.round()
      |> Kernel.trunc()

    graph =
      graph
      |> Graph.modify(:model, fn n -> text(n, ~s"#{model}") end)
      |> Graph.modify(:serial, fn n -> text(n, ~s"#{inspect(serial)}") end)
      |> Graph.modify(:total, fn n -> text(n, ~s"#{totalkWh} kWh") end)
      |> Graph.modify(:health, fn n ->
        text(n, ~s"#{inspect(health_code)} #{Atom.to_string(health_name)}")
      end)

    Process.send_after(self(), :update, 1000)
    {:noreply, graph, push: graph}
  end
end
