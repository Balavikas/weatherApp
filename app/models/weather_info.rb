class WeatherInfo
    def initialize(data)
        @data = data.with_indifferent_access
    end

    def city
        @data.dig(:name)
    end

    def sky
        weather[:description]
    end

    def icon
        "https://openweathermap.org/img/wn/#{weather[:icon]}@2x.png"
    end

    def temperature
        @data.dig(:main, :temp)
    end

    private

    def weather
        @data[:weather][0]
    end
end