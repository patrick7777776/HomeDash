defmodule HomeDash.Data.WeatherIcons do
  use GenServer
  require Logger
  @name __MODULE__

  def init(_) do
    weather_icons = load_icons()
    {:ok, weather_icons}
  end

  def handle_call({:get_hash, code}, _, weather_icons) do
    image_hash = Map.get(weather_icons, code, nil)
    {:reply, image_hash, weather_icons}
  end

  def start_link(args) do
    GenServer.start_link(@name, args, name: @name)
  end

  def get_image_hash(code) do
    GenServer.call(@name, {:get_hash, code})
  end

  @sig_code %{
    # Clear night
    0 => "moon_t_s.png",
    # Sunny day
    1 => "sun_t_s.png",
    # Partly cloudy (night)
    2 => "moon_cloud_t_s.png",
    # Partly cloudy (day)
    3 => "sun_cloud_t_s.png",
    # Not used
    4 => "",
    # Mist
    5 => "fog_t_s.png",
    # Fog
    6 => "fog_t_s.png",
    # Cloudy
    7 => "sun_cloud_t_s.png",
    # Overcast
    8 => "cloud_t_s.png",
    # Light rain shower (night)
    9 => "moon_cloud_rain_t_s.png",
    # Light rain shower (day)
    10 => "sun_cloud_rain_t_s.png",
    # Drizzle
    11 => "sun_cloud_rain_t_s.png",
    # Light rain
    12 => "sun_cloud_rain_t_s.png",
    # Heavy rain shower (night)
    13 => "moon_cloud_rain_t_s.png",
    # Heavy rain shower (day)
    14 => "sun_cloud_rain_t_s.png",
    # Heavy rain
    15 => "sun_cloud_rain_t_s.png",
    # Sleet shower (night)
    16 => "sleet_t_s.png",
    # Sleet shower (day)
    17 => "sleet_t_s.png",
    # Sleet
    18 => "sleet_t_s.png",
    # Hail shower (night)
    19 => "sleet_t_s.png",
    # Hail shower (day)
    20 => "sleet_t_s.png",
    # Hail
    21 => "sleet_t_s.png",
    # Light snow shower (night)
    22 => "snow_t_s.png",
    # Light snow shower (day)
    23 => "snow_t_s.png",
    # Light snow
    24 => "snow_t_s.png",
    # Heavy snow shower (night)
    25 => "snow_t_s.png",
    # Heavy snow shower (day)
    26 => "snow_t_s.png",
    # Heavy snow
    27 => "snow_t_s.png",
    # Thunder shower (night)
    28 => "thunder_t_s.png",
    # Thunder shower (day)
    29 => "thunder_t_s.png",
    # Thunder
    30 => "thunder_t_s.png"
  }

  defp load_icons() do
    name_to_hash =
      :code.priv_dir(:home_dash)
      |> Path.join("/static/weather_icons/*.png")
      |> Path.wildcard()
      |> Enum.reduce(%{}, fn path, map ->
        name = Path.basename(path)
        hash = Scenic.Cache.Support.Hash.file!(path, :sha)
        Logger.info(~s"#{path} -- #{hash}")
        Scenic.Cache.Static.Texture.load(path, hash)
        Map.put(map, name, hash)
      end)

    @sig_code
    |> Enum.map(fn {code, name} -> {code, Map.get(name_to_hash, name, nil)} end)
    |> Enum.into(%{})
  end
end
