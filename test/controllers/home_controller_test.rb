require "test_helper"
require "minitest/mock"

class HomeControllerTest < ActionDispatch::IntegrationTest
  WEATHER = {
    "name" => "Frisco",
    "timezone" => -18000,
    "weather" => [ { "main" => "Clear", "description" => "clear sky", "icon" => "01d" } ],
    "main" => { "temp" => 21.4, "feels_like" => 20.8, "temp_min" => 19.0, "temp_max" => 23.2, "humidity" => 40, "pressure" => 1015 },
    "wind" => { "speed" => 3.5 },
    "visibility" => 10000,
    "sys" => { "country" => "US", "sunrise" => 1_700_000_000, "sunset" => 1_700_040_000 }
  }.freeze

  def stub_weather(result)
    service = Minitest::Mock.new
    service.expect(:call, result)
    WeatherService.stub(:new, ->(**args) { @service_args = args; service }) { yield }
  end

  test "index renders the search form" do
    get root_path
    assert_response :success
    assert_select "form.search input[name=city][role=combobox]"
  end

  test "search renders the weather card" do
    stub_weather(WEATHER) { get search_path, params: { city: "Frisco" } }

    assert_response :success
    assert_select ".weather-card--clear-day"
    assert_select ".weather-card__city", /Frisco/
    assert_select ".weather-card__temp", /21/
    assert_select ".alert-banner", false
  end

  test "search passes coordinates from a picked suggestion" do
    stub_weather(WEATHER) { get search_path, params: { city: "Frisco, Texas, US", lat: "33.15", lon: "-96.82" } }

    assert_equal "33.15", @service_args[:lat]
    assert_equal "-96.82", @service_args[:lon]
  end

  test "search shows an error for an unknown city without leaking the flash" do
    stub_weather({ error: "City not found" }) { get search_path, params: { city: "Nowhereville" } }

    assert_response :success
    assert_select ".alert-banner", /City not found/
    assert_select ".weather-card", false

    get root_path
    assert_select ".alert-banner", false
  end

  test "search shows a service error when the API call fails" do
    stub_weather({ error: "Failed to fetch data" }) { get search_path, params: { city: "Frisco" } }

    assert_select ".alert-banner", /Couldn't load the weather/
  end
end
