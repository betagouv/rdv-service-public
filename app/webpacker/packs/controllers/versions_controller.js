import { Controller } from "stimulus"

export default class extends Controller {

  static targets = [ "title", "body" ]

  initialize() {
    this.loaded = false;
    this.displayed = false;
  }

  connect() {
    if (window.location.hash != "#history") return;

    this.toggle()
  }

  toggle(event) {
    if (event) { event.preventDefault() }
    this.displayed = !this.displayed
    const textKey = this.displayed ? "close" : "open"
    this.titleTarget.textContent = this.titleTarget.getAttribute(`data-text-${textKey}`)
    $(this.bodyTarget).collapse(this.displayed ? "show" : "hide")
    if (!this.loaded && this.displayed) {
      fetch(this.data.get("url"))
        .then(res => res.text())
        .then(text => {
          this.bodyTarget.innerHTML = text
          this.loaded = true
        })
    }
    history.replaceState(null, null, this.displayed ? "#history" : "#")
  }
}
