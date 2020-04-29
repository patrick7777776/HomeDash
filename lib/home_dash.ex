defmodule HomeDash do
  def start(_type, _args) do
    children = [
      {Scenic, viewports: [Application.get_env(:home_dash, :viewport)]},
      {HomeDash.Data.Inverter, nil},
      {HomeDash.Data.InverterFetcher, nil},
      {HomeDash.Data.WeatherIcons, nil},
      {HomeDash.Data.MetWeather, nil},
      {HomeDash.Data.MetWeatherFetcher, nil}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
