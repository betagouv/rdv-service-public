require("@rails/ujs").start()
import "@hotwired/turbo-rails"

// Nous ne souhaitons pas utiliser Turbo Drive (voir #4790 et #5917)
Turbo.session.drive = false

import { AddressAutocomplete } from './components/address-autocomplete.js'
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
  new AddressAutocomplete();
  CounterField();
  DsfrNewPassword();
  DsfrAlertClose();
  PreventDefault();
  setupCopyToClipBoardButtons()

  const whereInput = document.querySelector('#search_where');
  const submitButton = document.querySelector('#search_submit');
  const departementInput = document.querySelector('#search_departement')
  const whereErrorMessage = document.querySelector('#search-where-error')
  if (departementInput) {
    // le champ caché departement n'est rempli que lorsqu'une suggestion d'adresse a été choisie
    departementInput.addEventListener('change', () => {
      const valid = [2, 3].includes(departementInput.value.length)
      whereInput.classList.toggle('fr-input--valid', valid)
      whereInput.classList.toggle('fr-input--error', !valid)
      whereInput.setAttribute('aria-invalid', String(!valid))
      whereErrorMessage.classList.toggle('fr-hidden', valid)
      if (!valid) whereErrorMessage.textContent = "Veuillez sélectionner votre adresse dans la liste de suggestions"
      submitButton.disabled = !valid
    })
  }
});

import "@hotwired/turbo-rails"

import { Application } from "@hotwired/stimulus"
window.Stimulus = Application.start()

// Utilisé sur le formulaire de file d'attente proposé à l'usager
import FormController from './controllers/form_controller'
Stimulus.register('form', FormController)
