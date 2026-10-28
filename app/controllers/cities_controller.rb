class CitiesController < ApplicationController
    def index
        render json: CitySuggestionService.new(query: params[:q]).call
    end
end
