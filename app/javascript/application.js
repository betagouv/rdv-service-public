require("@rails/ujs").start()
// Nous souhaitons passer de Turbolinks à Turbo
// Dans un premier temps, nous ajoutons Turbo à l'application sans supprimer Turbolinks et nous désactivons le drive de Turbo.
// Cela nous permet d’utiliser les Turbo Streams et les Turbo Frames pour pouvoir supprimer l’usage des js.erb.
// Dans un second temps, nous supprimerons Turbolinks et nous activerons le drive de Turbo.
require("turbolinks").start()
import "@hotwired/turbo-rails"
Turbo.session.drive = false

import { PlacesInputs } from './components/places-inputs.js'
import { Modal } from './components/modal';
import { NameInitialsForm } from './components/name-initials-form';
import CounterField from './components/counter-field';
import DsfrNewPassword from "./components/dsfr-new-password";
import DsfrAlertClose from "./components/dsfr-alert-close";
import PreventDefault from "./components/prevent-default";
import './components/browser-detection';
import 'bootstrap';

import './stylesheets/application';
import './stylesheets/print';

new Modal();

$(document).on('turbolinks:load', function() {
  new PlacesInputs();
  new NameInitialsForm();
  CounterField();
  DsfrNewPassword();
  DsfrAlertClose();
  PreventDefault();

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
import "./controllers"
import "@hotwired/turbo-rails"
