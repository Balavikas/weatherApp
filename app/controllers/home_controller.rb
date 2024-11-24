class HomeController < ApplicationController
    def index
    end

    def search
        flash[:alert] = "City not found. Please enter a valid city name."
        @city = params[:city].present? ? params[:city] : 'Frisco'
        data = WeatherService.new(city: @city, units: 'metric').call
        @WeatherInfo = WeatherInfo.new(data)
    end
end
