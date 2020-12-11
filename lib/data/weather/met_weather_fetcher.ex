defmodule HomeDash.Data.MetWeatherFetcher do
  use GenServer
  require Logger
  alias HomeDash.Data.MetWeather
  @name __MODULE__
  @initial_fetch_delay 5 * 1000
  @retry_fetch_delay 60 * 1000
  @fetch_interval 60 * 60 * 1000

  # TODO: -- what time format do we need for querying? Do we need to translate to local time??

  def init(_) do
    Process.send_after(self(), :fetch, @initial_fetch_delay)

    # TODO: just look these up in the actual fetch!?
    {:ok,
     %{
       client_id: Application.get_env(:home_dash, :met_weather_apikey),
       secret: Application.get_env(:home_dash, :met_weather_secret),
       latitude: Application.get_env(:home_dash, :met_weather_latitude),
       longtitude: Application.get_env(:home_dash, :met_weather_longtitude)
     }}
  end

  def handle_info(
        :fetch,
        %{client_id: client_id, secret: secret, latitude: latitude, longtitude: longtitude} =
          state
      ) do
    with {:ok, hourly_forecasts} <- fetch(latitude, longtitude, client_id, secret) do
      MetWeather.update_forecasts(hourly_forecasts)
      Process.send_after(self(), :fetch, @fetch_interval)
    else
      _ ->
        Process.send_after(self(), :fetch, @retry_fetch_delay)
    end

    {:noreply, state}
  end

  def start_link(args) do
    GenServer.start_link(@name, args, name: @name)
  end

  def fetch(
        lat,
        long,
        client_id,
        secret
      ) do
    Logger.info("Fetching weather update")

    resp =
      HTTPoison.get(
        ~s"https://api-metoffice.apiconnect.ibmcloud.com/metoffice/production/v0/forecasts/point/hourly?excludeParameterMetadata=true&includeLocationName=false&latitude=#{
          lat
        }&longitude=#{long}",
        Accept: "Application/json; Charset=utf-8",
        "x-ibm-client-id": client_id,
        "x-ibm-client-secret": secret
      )

    with {:ok, response} <- resp,
         met <- Jason.decode!(response.body),
         {:ok, [features | _]} <- Map.fetch(met, "features"),
         {:ok, properties} <- Map.fetch(features, "properties"),
         {:ok, time_series} <- Map.fetch(properties, "timeSeries") do
      elems =
        time_series
        |> Enum.map(fn e -> convert(e) end)

      {:ok, elems}
    else
      err -> err
    end

    # TODO: sunset/sunrise
  end

  def convert(
        %{
          "time" => time,
          "significantWeatherCode" => code,
          "uvIndex" => uv_index,
          "visibility" => visibility,
          "probOfPrecipitation" => precipitation_prob,
          "screenTemperature" => temperature
        } = _elem
      ) do
    {:ok, datetime} = Timex.parse(time, "{RFC3339z}")
    timestamp = Timex.to_unix(datetime)

    # hour in day for easy lookup / placement in ui -- what about daylight savings time?? TODO
    n = Timex.to_naive_datetime(datetime)
    hour = n.hour

    %{
      timestamp: timestamp,
      hour: hour,
      code: code,
      uv_index: uv_index,
      visibility: visibility,
      temperature: temperature,
      precipitation_prob: precipitation_prob
    }
  end
end
