use Mix.Config

config :home_dash, :viewport, %{
  name: :main_viewport,
  size: {800, 480},
  default_scene: {HomeDash.Scene.Home, nil},
  drivers: [
    %{
      module: Scenic.Driver.Glfw,
      name: :glfw,
      opts: [resizeable: false, title: "home_dash"]
    }
  ]
}

import_config ~s"#{Mix.env()}.secrets.exs"
