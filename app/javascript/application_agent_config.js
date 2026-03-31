require("@rails/ujs").start()
import "@hotwired/turbo-rails"

// Nous ne souhaitons pas utiliser Turbo Drive (voir #4790 et #5917)
Turbo.session.drive = false

import DsfrNewPassword from "./components/dsfr-new-password";
import DsfrAlertClose from "./components/dsfr-alert-close";
import { Modal } from './components/modal';
import './components/browser-detection';
import 'select2/dist/js/select2';
import 'select2/dist/js/i18n/fr.js';
import { initializeSelect2 } from './components/select2-inputs';
import 'bootstrap';
import setupCopyToClipBoardButtons from './components/copy_to_clipboard_button.js'

import './stylesheets/application_agent_config';
import './stylesheets/print';

new Modal();
initializeSelect2();

document.addEventListener("DOMContentLoaded", function () {
  DsfrNewPassword();
  DsfrAlertClose();

  setupCopyToClipBoardButtons()
});
