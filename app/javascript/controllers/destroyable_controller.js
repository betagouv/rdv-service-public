import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="destroyable"
export default class extends Controller {
  static targets = [
    "destroyInput"
  ]

  destroyItem = (event) => {
    event.preventDefault();
    this.element.classList.add("d-none");
    this.destroyInputTarget.value = true;
  }
}


