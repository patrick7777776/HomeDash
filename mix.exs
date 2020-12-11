defmodule HomeDash.MixProject do
  use Mix.Project

  def project do
    [
      app: :home_dash,
      version: "0.1.0",
      elixir: "~> 1.7",
      build_embedded: true,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {HomeDash, []},
      extra_applications: []
    ]
  end

  defp deps do
    [
      {:qsb36, "~> 0.1.1"},
      {:scenic, "~> 0.10"},
      {:scenic_driver_glfw, "~> 0.10", targets: :host},
      {:ex2ms, "~> 1.0"},
      {:timex, "~> 3.5"},
      {:httpoison, "~> 1.7"},
      {:jason, "~> 1.1"}
    ]
  end
end
