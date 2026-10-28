class WeatherInfo
    def initialize(data)
        @data = data.with_indifferent_access
    end

    def found?
        @data[:error].blank? && city.present? && weather.present?
    end

    def not_found?
        @data[:error] == "City not found"
    end

    def city
        @data.dig(:name)
    end

    def country
        @data.dig(:sys, :country)
    end

    def sky
        weather[:description]
    end

    def condition
        weather[:main]
    end

    def icon
        "https://openweathermap.org/img/wn/#{weather[:icon]}@4x.png"
    end

    def temperature
        @data.dig(:main, :temp)&.round
    end

    def feels_like
        @data.dig(:main, :feels_like)&.round
    end

    def temp_min
        @data.dig(:main, :temp_min)&.round
    end

    def temp_max
        @data.dig(:main, :temp_max)&.round
    end

    def humidity
        @data.dig(:main, :humidity)
    end

    def pressure
        @data.dig(:main, :pressure)
    end

    # API returns m/s for metric units.
    def wind_speed_kmh
        speed = @data.dig(:wind, :speed)
        speed && (speed * 3.6).round
    end

    def visibility_km
        meters = @data[:visibility]
        meters && (meters / 1000.0).round(1)
    end

    def local_time
        to_local(Time.now.to_i)
    end

    def sunrise
        to_local(@data.dig(:sys, :sunrise))
    end

    def sunset
        to_local(@data.dig(:sys, :sunset))
    end

    # CSS modifier for the card background, e.g. "clear-day", "rain-night".
    def theme
        "#{condition.to_s.downcase.presence || 'default'}-#{weather[:icon].to_s.end_with?('n') ? 'night' : 'day'}"
    end

    private

    def weather
        Array(@data[:weather]).first || {}
    end

    # Converts a unix timestamp to the city's local time using the API's UTC offset (seconds).
    def to_local(timestamp)
        return if timestamp.nil?

        Time.at(timestamp, in: @data[:timezone].to_i)
    end
end
