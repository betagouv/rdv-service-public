require("@rails/ujs").start()
require("turbolinks").start()
import { Datetimepicker } from './components/datetimepicker';
import { PlacesInputs } from './components/places-inputs.js'
import './components/analytic.js';
import { Modal } from './components/modal';
import { ShowHidePassword } from './components/show-hide-password.js';
import { NameInitialsForm } from './components/name-initials-form';
import './components/browser-detection';
import 'select2/dist/js/select2.min.js';
import 'select2/dist/js/i18n/fr.js';
import { Select2Inputs } from './components/select2-inputs';
import 'bootstrap';

import './stylesheets/application';
import './stylesheets/print';

new Modal();
new Select2Inputs();

$(document).on('turbolinks:load', function() {
  Holder.run();

  new ShowHidePassword();
  new Datetimepicker();
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
