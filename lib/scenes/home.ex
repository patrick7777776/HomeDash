defmodule HomeDash.Scene.Home do
  use Scenic.Scene
  alias Scenic.Graph
  alias HomeDash.Component.Navigation
  import HomeDash.Util.Constants, only: [scenes: 0]

  def init(_args, _opts) do
    graph =
      Graph.build()
      |> Navigation.add_to_graph({__MODULE__, "Home", scenes()})

    {:ok, graph, push: graph}
  end
end
