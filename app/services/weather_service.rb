class WeatherService

    BASE_URL = "https://api.openweathermap.org/data/2.5/weather"

    attr_reader :city, :lat, :lon, :units

    def initialize(city:, units:, lat: nil, lon: nil)
        @city = city
        @lat = lat
        @lon = lon
        @units = units
    end

    def call
        @response = Net::HTTP.get_response(uri)
        response_body = JSON.parse(@response.body)

        # Check for 404 error
        if response_body['cod'].to_s == '404'
          return { error: "City not found" }
        elsif @response.is_a?(Net::HTTPSuccess)
          return response_body
        else
          Rails.logger.warn("WeatherService: OpenWeatherMap returned #{@response.code}: #{response_body['message']}")
          return { error: "Failed to fetch data" }
        end
    rescue StandardError => e
        Rails.logger.error("WeatherService failed: #{e.class}: #{e.message}")
        { error: "Failed to fetch data" }
    end


    private

    def uri
        @uri = URI(BASE_URL)
        @uri.query = URI.encode_www_form(location_params.merge(units: @units, appid: ENV['API_KEY']))
        return @uri
    end

    # Prefer exact coordinates (set when a suggestion is picked) over a free-text city name.
    def location_params
        if @lat.present? && @lon.present?
          { lat: @lat, lon: @lon }
        else
          { q: @city }
        end
    end
end
