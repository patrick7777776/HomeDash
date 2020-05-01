defmodule HomeDash do
  def start(_type, _args) do
    children = [
      {HomeDash.Data.Inverter, nil},
      {HomeDash.Data.InverterFetcher, nil},
      {HomeDash.Data.MetWeather, nil},
      {HomeDash.Data.MetWeatherFetcher, nil},
      {Scenic, viewports: [Application.get_env(:home_dash, :viewport)]},
      {HomeDash.Data.WeatherIcons, nil}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
