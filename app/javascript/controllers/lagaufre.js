import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const button = document.getElementById("gaufre_button");

    window._lasuite_widget = window._lasuite_widget || [];

    _lasuite_widget.push(['lagaufre', 'init', {
      api: 'https://lasuite.numerique.gouv.fr/api/services',
      background: 'linear-gradient(180deg, #eceffd 0%, #FFFFFF 20%)',
      buttonElement: button,
      position: 'fixed',
      top: 60,
      right: 10
    }]);
  }
}