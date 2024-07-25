require("@rails/ujs").start()
require("turbolinks").start()
import { PlacesInputs } from './components/places-inputs.js'
import { Modal } from './components/modal';
import { ShowHidePassword } from './components/show-hide-password.js';
import { NameInitialsForm } from './components/name-initials-form';
import './components/browser-detection';
import 'bootstrap';

import './stylesheets/application';
import './stylesheets/print';

new Modal();

$(document).on('turbolinks:load', function() {
  new ShowHidePassword();
  new PlacesInputs();
  new NameInitialsForm();

  const whereInput = document.querySelector('#search_where');
  const submitButton = document.querySelector('#search_submit');
  const departementInput = document.querySelector('#search_departement')
  if (departementInput) {
    departementInput.addEventListener('change', event => {
      const valid = [2, 3].includes(departementInput.value.length)
      whereInput.classList.toggle('is-valid', valid)
      whereInput.classList.toggle('is-invalid', !valid)
      $(submitButton).attr('disabled', !valid)
    })
  }
});
