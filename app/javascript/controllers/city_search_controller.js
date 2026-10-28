import { Controller } from "@hotwired/stimulus"

// Autocomplete for the city search box. Fetches suggestions from /cities and,
// when one is picked, submits the form with its exact coordinates.
export default class extends Controller {
  static targets = ["input", "lat", "lon", "list"]
  static values = { url: String, minLength: { type: Number, default: 2 }, delay: { type: Number, default: 250 } }

  connect() {
    this.suggestions = []
    this.activeIndex = -1
  }

  disconnect() {
    clearTimeout(this.timeout)
    this.abortController?.abort()
  }

  search() {
    // Typed text no longer matches a picked suggestion.
    this.latTarget.value = ""
    this.lonTarget.value = ""

    clearTimeout(this.timeout)
    const query = this.inputTarget.value.trim()
    if (query.length < this.minLengthValue) return this.close()

    this.timeout = setTimeout(() => this.fetchSuggestions(query), this.delayValue)
  }

  async fetchSuggestions(query) {
    this.abortController?.abort()
    this.abortController = new AbortController()

    try {
      const url = new URL(this.urlValue, window.location.origin)
      url.searchParams.set("q", query)
      const response = await fetch(url, { headers: { Accept: "application/json" }, signal: this.abortController.signal })
      if (!response.ok) return this.close()

      this.suggestions = await response.json()
      this.render()
    } catch (error) {
      if (error.name !== "AbortError") this.close()
    }
  }

  render() {
    this.activeIndex = -1
    this.listTarget.replaceChildren()

    if (this.suggestions.length === 0) {
      const empty = document.createElement("li")
      empty.className = "search__empty"
      empty.textContent = "No matching cities"
      this.listTarget.append(empty)
    }

    this.suggestions.forEach((city, index) => {
      const item = document.createElement("li")
      item.className = "search__suggestion"
      item.id = `city-suggestion-${index}`
      item.setAttribute("role", "option")

      const name = document.createElement("span")
      name.className = "search__suggestion-name"
      name.textContent = city.name
      const region = document.createElement("span")
      region.className = "search__suggestion-region"
      region.textContent = [city.state, city.country].filter(Boolean).join(", ")
      item.append(name, region)

      // mousedown fires before the input loses focus, so the click isn't swallowed.
      item.addEventListener("mousedown", (event) => {
        event.preventDefault()
        this.select(index)
      })
      this.listTarget.append(item)
    })

    this.open()
  }

  navigate(event) {
    if (this.listTarget.hidden) return

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.highlight(Math.min(this.activeIndex + 1, this.suggestions.length - 1))
        break
      case "ArrowUp":
        event.preventDefault()
        this.highlight(Math.max(this.activeIndex - 1, 0))
        break
      case "Enter":
        if (this.activeIndex >= 0) {
          event.preventDefault()
          this.select(this.activeIndex)
        }
        break
      case "Escape":
        this.close()
        break
    }
  }

  highlight(index) {
    if (this.suggestions.length === 0) return

    this.activeIndex = index
    this.listTarget.querySelectorAll("[role=option]").forEach((item, i) => {
      item.setAttribute("aria-selected", i === index)
    })
    this.inputTarget.setAttribute("aria-activedescendant", `city-suggestion-${index}`)
  }

  select(index) {
    const city = this.suggestions[index]
    if (!city) return

    this.inputTarget.value = city.label
    this.latTarget.value = city.lat
    this.lonTarget.value = city.lon
    this.close()
    this.element.requestSubmit()
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  open() {
    this.listTarget.hidden = false
    this.inputTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    this.listTarget.hidden = true
    this.activeIndex = -1
    this.inputTarget.setAttribute("aria-expanded", "false")
    this.inputTarget.removeAttribute("aria-activedescendant")
  }
}
