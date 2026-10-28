class CitySuggestionService

    BASE_URL = "https://api.openweathermap.org/geo/1.0/direct"
    LIMIT = 5
    MIN_QUERY_LENGTH = 2

    def initialize(query:)
        @query = query.to_s.strip
    end

    # Returns an array of { name:, state:, country:, lat:, lon:, label: } hashes.
    def call
        return [] if @query.length < MIN_QUERY_LENGTH

        # Failures return nil, which skip_nil keeps out of the cache so they're retried.
        suggestions = Rails.cache.fetch(["city_suggestions", @query.downcase], expires_in: 1.day, skip_nil: true) do
          response = Net::HTTP.get_response(uri)
          unless response.is_a?(Net::HTTPSuccess)
            Rails.logger.warn("CitySuggestionService: OpenWeatherMap returned #{response.code}: #{response.body}")
            next nil
          end

          JSON.parse(response.body).map { |city| format(city) }.uniq { |city| city[:label] }
        end
        suggestions || []
    rescue StandardError => e
        Rails.logger.error("CitySuggestionService failed: #{e.class}: #{e.message}")
        []
    end

    private

    def uri
        uri = URI(BASE_URL)
        uri.query = URI.encode_www_form(q: @query, limit: LIMIT, appid: ENV['API_KEY'])
        uri
    end

    def format(city)
        {
          name: city["name"],
          state: city["state"],
          country: city["country"],
          lat: city["lat"],
          lon: city["lon"],
          label: [city["name"], city["state"], city["country"]].compact_blank.join(", ")
        }
    end
end
