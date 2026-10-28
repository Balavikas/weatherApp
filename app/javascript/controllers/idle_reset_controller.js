import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Sends visitors back to a fresh search once a results page has sat idle, so someone
// returning to the tab (or coming back via history) doesn't see an old city's weather.
export default class extends Controller {
  static values = {
    url: String,
    after: { type: Number, default: 5 * 60 * 1000 },
    // Stored on the element so Turbo's cached snapshot of the page keeps the original time.
    lastActiveAt: Number
  }

  connect() {
    if (!this.lastActiveAtValue) this.lastActiveAtValue = Date.now()
    this.interval = setInterval(() => this.check(), 15000)
    this.check()
  }

  disconnect() {
    clearInterval(this.interval)
  }

  touch() {
    this.lastActiveAtValue = Date.now()
  }

  // Also runs on tab focus and back/forward restores, since background-tab timers get throttled.
  check() {
    if (Date.now() - this.lastActiveAtValue < this.afterValue) return

    clearInterval(this.interval)
    Turbo.visit(this.urlValue, { action: "replace" })
  }
}
