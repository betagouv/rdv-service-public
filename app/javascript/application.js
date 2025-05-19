require("@rails/ujs").start()
require("turbolinks").start()
import { PlacesInputs } from './components/places-inputs.js'
import { Modal } from './components/modal';
import { NameInitialsForm } from './components/name-initials-form';
import CounterField from './components/counter-field';
import DsfrNewPassword from "./components/dsfr-new-password";
import './components/browser-detection';
import 'bootstrap';

import './stylesheets/application';
import './stylesheets/print';

new Modal();

$(document).on('turbolinks:load', function() {
  new PlacesInputs();
  new NameInitialsForm();
  DsfrNewPassword();
  CounterField();

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
