import { Controller } from "@hotwired/stimulus"

// Recharge la page vers l'URL donnée (checked / unchecked) quand la case change
export default class extends Controller {
  static values = { checkedUrl: String, uncheckedUrl: String }

  go(event) {
    window.location.href = event.target.checked ? this.checkedUrlValue : this.uncheckedUrlValue
  }
}
