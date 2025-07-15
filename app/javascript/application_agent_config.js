require("@rails/ujs").start()
// Nous souhaitons passer de Turbolinks à Turbo
// Dans un premier temps, nous ajoutons Turbo à l'application sans supprimer Turbolinks et nous désactivons le drive de Turbo.
// Cela nous permet d’utiliser les Turbo Streams et les Turbo Frames pour pouvoir supprimer l’usage des js.erb.
// Dans un second temps, nous supprimerons Turbolinks et nous activerons le drive de Turbo.
require("turbolinks").start()
import "@hotwired/turbo-rails"
Turbo.session.drive = false

import DsfrNewPassword from "./components/dsfr-new-password";
import { Modal } from './components/modal';
import './components/browser-detection';
import 'select2/dist/js/select2.full.js';
import 'select2/dist/js/i18n/fr.js';
import { Select2Inputs } from './components/select2-inputs';
import 'bootstrap';
import { Clipboard } from './components/clipboard.js'

import './stylesheets/application_agent_config';
import './stylesheets/print';

new Modal();
new Select2Inputs();

$(document).on('turbolinks:load', function () {
  DsfrNewPassword();

  new Clipboard();
});
