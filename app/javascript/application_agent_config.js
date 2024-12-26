require("@rails/ujs").start()
require("turbolinks").start()
import { DsfrNewPassword } from "./components/dsfr-new-password";
import { Modal } from './components/modal';
import './components/browser-detection';
import 'select2/dist/js/select2.min.js';
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
