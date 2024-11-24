class WeatherService

    BASE_URL = "https://api.openweathermap.org/data/2.5/weather"
    API_KEY = "8084bd39b5899d5f30c2382ce2f36347"

    attr_reader :city, :metric
    
    def initialize(city:, units:)
        @city = city
        @units = units
    end

    def call
        @response = Net::HTTP.get_response(uri)
        response_body = JSON.parse(@response.body)
      
        # Check for 404 error
        if response_body['cod'] == '404'
          return { error: "City not found" } # Return error message instead of just returning
        elsif @response.is_a?(Net::HTTPSuccess)
          return response_body # Return the parsed JSON if the request was successful
        else
          return { error: "Failed to fetch data" } # Return error message if not a successful response
        end
    end
      

    private

    def uri
        @uri = URI(BASE_URL)
        params = {q: @city, units: @units, appid: ENV['API_KEY']}
        @uri.query = URI.encode_www_form(params)
        return @uri
    end
end