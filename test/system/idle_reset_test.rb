require "application_system_test_case"
require "minitest/mock"

class IdleResetTest < ApplicationSystemTestCase
  WEATHER = {
    "name" => "London",
    "timezone" => 0,
    "weather" => [ { "main" => "Clouds", "description" => "overcast clouds", "icon" => "04d" } ],
    "main" => { "temp" => 12.3, "feels_like" => 11.0, "temp_min" => 10.0, "temp_max" => 14.0, "humidity" => 70, "pressure" => 1012 },
    "wind" => { "speed" => 4.0 },
    "visibility" => 10000,
    "sys" => { "country" => "GB", "sunrise" => 1_700_000_000, "sunset" => 1_700_030_000 }
  }.freeze

  def with_weather(&block)
    WeatherService.stub(:new, ->(**) { Struct.new(:call).new(WEATHER) }, &block)
  end

  # Pretends the visitor's last activity was `ms` ago, then simulates them returning to the tab.
  def idle_for(ms)
    execute_script(<<~JS)
      document.querySelector("[data-controller~='idle-reset']").dataset.idleResetLastActiveAtValue = Date.now() - #{ms}
      document.dispatchEvent(new Event("visibilitychange"))
    JS
  end

  test "returns to a fresh search after 5 idle minutes" do
    with_weather do
      visit search_path(city: "London")
      assert_selector ".weather-card__city", text: "London"

      idle_for(5 * 60 * 1000 + 1000)

      assert_current_path root_path
      assert_selector ".hero__title"
      assert_no_selector ".weather-card"
      assert_equal "", find("input[name=city]").value
    end
  end

  test "keeps the results while the visitor is recently active" do
    with_weather do
      visit search_path(city: "London")
      idle_for(4 * 60 * 1000)

      assert_current_path search_path(city: "London")
      assert_selector ".weather-card__city", text: "London"
    end
  end
end
