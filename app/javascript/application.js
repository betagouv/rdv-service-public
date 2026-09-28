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
});

import "@hotwired/turbo-rails"

import { Application } from "@hotwired/stimulus"
window.Stimulus = Application.start()

// Utilisé sur le formulaire de file d'attente proposé à l'usager
import FormController from './controllers/form_controller'
Stimulus.register('form', FormController)

// Utilisé sur la recherche d'adresse de la page d'accueil RDVS
import AddressSearchController from './controllers/address_search_controller'
Stimulus.register('address-search', AddressSearchController)
