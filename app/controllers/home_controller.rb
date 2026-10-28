class HomeController < ApplicationController
    def index
    end

    def search
        @city = params[:city].present? ? params[:city] : 'Frisco'
        data = WeatherService.new(city: @city, lat: params[:lat], lon: params[:lon], units: 'metric').call
        @weather = WeatherInfo.new(data)
        unless @weather.found?
          flash.now[:alert] = if @weather.not_found?
            "City not found. Please enter a valid city name."
          else
            "Couldn't load the weather right now. Please try again in a moment."
          end
        end
    end
end
