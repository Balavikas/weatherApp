require "test_helper"
require "minitest/mock"

class CitiesControllerTest < ActionDispatch::IntegrationTest
  test "returns suggestions as json" do
    suggestions = [ { name: "Paris", state: "Ile-de-France", country: "FR", lat: 48.85, lon: 2.35, label: "Paris, Ile-de-France, FR" } ]
    service = Minitest::Mock.new
    service.expect(:call, suggestions)

    CitySuggestionService.stub(:new, ->(**) { service }) { get cities_path, params: { q: "Par" } }

    assert_response :success
    assert_equal "Paris, Ile-de-France, FR", response.parsed_body.first["label"]
  end

  test "returns an empty list for short queries" do
    get cities_path, params: { q: "P" }

    assert_response :success
    assert_equal [], response.parsed_body
  end
end
