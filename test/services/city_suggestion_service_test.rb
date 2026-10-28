require "test_helper"
require "minitest/mock"

class CitySuggestionServiceTest < ActiveSupport::TestCase
  GEOCODING_BODY = [
    { "name" => "London", "state" => "England", "country" => "GB", "lat" => 51.5, "lon" => -0.12 }
  ].to_json

  def ok_response
    response = Net::HTTPOK.new("1.1", "200", "OK")
    response.instance_variable_set(:@body, GEOCODING_BODY)
    response.instance_variable_set(:@read, true)
    response
  end

  test "returns suggestions even when the cache store raises" do
    broken_cache = ->(*, **) { raise ActiveRecord::StatementInvalid, "no such table: solid_cache_entries" }

    result = Rails.cache.stub(:fetch, broken_cache) do
      Net::HTTP.stub(:get_response, ok_response) { CitySuggestionService.new(query: "London").call }
    end

    assert_equal [ "London, England, GB" ], result.map { |city| city[:label] }
  end

  test "returns an empty list when the API call fails" do
    result = Net::HTTP.stub(:get_response, ->(_) { raise SocketError, "offline" }) do
      CitySuggestionService.new(query: "London").call
    end

    assert_equal [], result
  end
end
