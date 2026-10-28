require "test_helper"

class WeatherInfoTest < ActiveSupport::TestCase
  test "is not found for an error response and does not raise" do
    info = WeatherInfo.new({ error: "City not found" })

    assert_not info.found?
    assert_nil info.sky
  end

  test "converts units and local times" do
    info = WeatherInfo.new(
      "name" => "Tokyo",
      "timezone" => 32400,
      "weather" => [ { "main" => "Rain", "description" => "light rain", "icon" => "10n" } ],
      "main" => { "temp" => 14.6 },
      "wind" => { "speed" => 5 },
      "visibility" => 8500,
      "sys" => { "sunrise" => 0 }
    )

    assert info.found?
    assert_equal 15, info.temperature
    assert_equal 18, info.wind_speed_kmh
    assert_equal 8.5, info.visibility_km
    assert_equal "rain-night", info.theme
    assert_equal "09:00", info.sunrise.strftime("%H:%M")
  end
end
