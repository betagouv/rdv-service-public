import 'core-js/stable'
import "regenerator-runtime/runtime"; // cf https://github.com/rails/webpacker#usage
require("@rails/ujs").start()
require("turbolinks").start()
require("chartkick")
require("chart.js")
import { PlacesInput } from 'components/places-input.js'
import { Datetimepicker } from 'components/datetimepicker';
import 'components/analytic.js';
import { Modal } from 'components/modal';
import { ShowHidePassword } from 'components/show-hide-password.js';
import 'components/browser-detection';
import 'select2/dist/js/select2.min.js';
import 'select2/dist/js/i18n/fr.js';
import 'jquery-mask-plugin';
import 'components/select2';
import 'components/sentry';
import 'components/search-form';
import 'bootstrap';

import 'stylesheets/application';
import 'stylesheets/print';

new Modal();

$(document).on('turbolinks:load', function() {
  $('input[type="tel"]').mask('00 00 00 00 00')
  Holder.run();

  new ShowHidePassword();
  new Datetimepicker();

  const placeJsContainer = document.querySelector('.places-js-container');
  if (placeJsContainer !== null) {
    new PlacesInput(placeJsContainer);
  }

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
