defmodule HomeDash.Component.Navigation do
  use Scenic.Component

  alias Scenic.ViewPort
  alias Scenic.Graph

  import Scenic.Primitives
  import Scenic.Components

  import HomeDash.Util, only: [neighbours: 2]
  import HomeDash.Util.Constants, only: [dark_button_theme: 0, col_3: 0]

  def init({current_scene, title, all_scenes}, opts) do
    {prev_scene, next_scene} = neighbours(all_scenes, current_scene)

    styles = opts[:styles] || %{}

    # Get the viewport width
    {:ok, %ViewPort.Status{size: {width, _}}} =
      opts[:viewport]
      |> ViewPort.info()

    # TODO: would be nicer to have custom icons rather than stupid <, >
    graph =
      Graph.build(styles: styles, font_size: 20)
      |> text(title, text_align: :center, font_size: 24, translate: {width / 2, 30}, fill: col_3())
      |> button("<", id: :prev_scene, width: 40, translate: {5, 5}, theme: dark_button_theme())
      |> button(">",
        id: :next_scene,
        width: 40,
        translate: {width - 40 - 5, 5},
        theme: dark_button_theme()
      )

    {:ok,
     %{graph: graph, viewport: opts[:viewport], next_scene: next_scene, prev_scene: prev_scene},
     push: graph}
  end

  # --------------------------------------------------------
  # blog: verify is applied to first arg passed to init!
  # move after init!
  def verify({scene, title, all_scenes}) when is_atom(scene) and is_binary(title) do
    case Enum.member?(all_scenes, scene) do
      true -> {:ok, {scene, title}}
      false -> :invalid_data
    end
  end

  # ----------------------------------------------------------------------------

  def filter_event({:click, :next_scene}, _, %{viewport: vp, next_scene: next_scene} = state) do
    ViewPort.set_root(vp, {next_scene, nil})
    {:halt, state}
  end

  def filter_event({:click, :prev_scene}, _, %{viewport: vp, prev_scene: prev_scene} = state) do
    ViewPort.set_root(vp, {prev_scene, nil})
    {:halt, state}
  end
end
