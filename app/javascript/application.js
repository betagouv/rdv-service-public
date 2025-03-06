require("@rails/ujs").start()
require("turbolinks").start()
import { AddressAutocomplete } from "./components/address-autocomplete";
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
  //new PlacesInputs();
  new NameInitialsForm();
  new AddressAutocomplete();
  DsfrNewPassword();
  CounterField();

  const whereInput = document.querySelector('#search_where');
  const submitButton = document.querySelector('#search_submit');
  const departementInput = document.querySelector('#search_departement')
  const whereErrorMessage = document.querySelector('#where-error-message')
  const whereErrorMessageText = document.querySelector('#where-error-message-text')
  if (departementInput) {
    departementInput.addEventListener('change', event => {
      const valid = [2, 3].includes(departementInput.value.length)
      whereInput.classList.toggle('fr-input--valid', valid)
      whereInput.classList.toggle('fr-input--error', !valid)
      whereInput.setAttribute('aria-invalid', String(!valid))
      whereErrorMessage.toggleAttribute('hidden', valid)
      if(valid) {
        whereErrorMessageText.innerHTML = ''
      } else {
        whereErrorMessageText.innerHTML = 'Adresse invalide : veuillez saisir votre adresse dans la barre de recherche puis sélectionner un choix dans la liste déroulante'
      }
      $(submitButton).attr('disabled', !valid)
    })
  }
});
