# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A small Rails 8 app (Ruby 3.3.6) that looks up current weather for a city via the OpenWeatherMap API and renders it with Bootstrap. There is no database-backed domain model; SQLite is only used by the default Solid Cache/Queue/Cable setup.

## Commands

- Setup: `bin/setup` (installs gems, prepares DB). Also run `yarn install` for the Sass build.
- Dev server: `bin/dev` — runs Procfile.dev (Rails server + `yarn build:css --watch`). CSS is compiled from `app/assets/stylesheets/application.sass.scss` into `app/assets/builds/` (gitignored), so the CSS watcher must be running or `yarn build:css` run once.
- Tests: `bin/rails test` (all), `bin/rails test test/controllers/home_controller_test.rb` (one file), `bin/rails test test/controllers/home_controller_test.rb:LINE` (one test). System tests: `bin/rails test:system`.
- Lint: `bin/rubocop` (rubocop-rails-omakase).
- Security scans: `bin/brakeman --no-pager`, `bin/importmap audit`.
- Deploy: Kamal (`bin/kamal deploy`), configured in `config/deploy.yml` (still contains placeholder server/registry values).

CI (`.github/workflows/ci.yml`) runs brakeman, importmap audit, rubocop, and tests on PRs and pushes to `main` — note the repo's branch is `master`, so pushes to it do not trigger CI.

## Architecture

Request flow: `GET /` → `HomeController#index` (search form) → `GET /search?city=...[&lat=..&lon=..]` → `HomeController#search`:

1. `WeatherService` (`app/services/weather_service.rb`) calls OpenWeatherMap's `/data/2.5/weather` with `Net::HTTP`, by `lat`/`lon` when present (set when a suggestion is picked) or else by city name. It returns the parsed JSON hash on success, or `{ error: "..." }` on 404 / failures / network errors. City defaults to "Frisco" when blank.
2. `WeatherInfo` (`app/models/weather_info.rb`) is a plain Ruby wrapper (not ActiveRecord) over the raw API hash. `found?` gates the view; `theme` (e.g. `clear-day`) maps to a `.weather-card--*` gradient in the stylesheet; times are converted to the city's local time using the API's `timezone` offset.
3. The controller sets `flash.now[:alert]` only when `found?` is false.

City autocomplete: the shared `home/_search_form` partial is driven by the `city-search` Stimulus controller (`app/javascript/controllers/city_search_controller.js`), which debounces input, fetches `GET /cities?q=` (`CitiesController` → `CitySuggestionService`, OpenWeatherMap Geocoding API, cached 1 day via `Rails.cache`), and on pick fills hidden `lat`/`lon` fields and submits. Calling OpenWeatherMap server-side keeps the API key out of the browser.

Gotchas:
- The API key is read from `ENV['API_KEY']` (loaded from `.env` via dotenv-rails in dev/test; `.env*` is gitignored).
- Styles live in `app/assets/stylesheets/application.sass.scss` (BEM-style classes, CSS variables with a dark-mode override) and load after the Bootstrap 5 CDN stylesheet. Fonts (Inter, Outfit) come from Google Fonts in the layout.
- The layout also renders a ScreenPlay tracking script (`layouts/partials/_screenplay_tracker`); the static `public/*.html` error pages include the same tag inline.
- Tests stub `WeatherService.new` / `CitySuggestionService.new` with `Minitest` `stub`; nothing hits the network.
