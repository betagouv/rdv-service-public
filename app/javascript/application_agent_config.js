require("@rails/ujs").start()
import { Datetimepicker } from './components/datetimepicker';
import { PlacesInputs } from './components/places-inputs.js'
import { Modal } from './components/modal';
import { ShowHidePassword } from './components/show-hide-password.js';
import { NameInitialsForm } from './components/name-initials-form';
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

document.addEventListener("DOMContentLoaded", function() {
  new ShowHidePassword();
  new Datetimepicker();
  new PlacesInputs();
  new NameInitialsForm();
  new Clipboard();
});
