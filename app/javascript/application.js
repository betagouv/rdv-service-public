require("@rails/ujs").start()
import "@hotwired/turbo-rails"

// Nous ne souhaitons pas utiliser Turbo Drive (voir #4790 et #5917)
Turbo.session.drive = false

import { PlacesInputs } from './components/places-inputs.js'
import { Modal } from './components/modal';
import CounterField from './components/counter-field';
import DsfrNewPassword from "./components/dsfr-new-password";
import DsfrAlertClose from "./components/dsfr-alert-close";
import PreventDefault from "./components/prevent-default";
import setupCopyToClipBoardButtons from './components/copy_to_clipboard_button.js'
import './components/browser-detection';
import 'bootstrap';

import './stylesheets/application';
import './stylesheets/print';

new Modal();

document.addEventListener("DOMContentLoaded", function() {
  new PlacesInputs();
  CounterField();
  DsfrNewPassword();
  DsfrAlertClose();
  PreventDefault();
  setupCopyToClipBoardButtons()

  const whereInput = document.querySelector('#search_where');
  const submitButton = document.querySelector('#search_submit');
  const departementInput = document.querySelector('#search_departement')
  if (departementInput) {
    departementInput.addEventListener('change', event => {
      const valid = [2, 3].includes(departementInput.value.length)
      whereInput.classList.toggle('fr-input--valid', valid)
      whereInput.classList.toggle('fr-input--error', !valid)
      $(submitButton).attr('disabled', !valid)
    })
  }
});
import "@hotwired/turbo-rails"
