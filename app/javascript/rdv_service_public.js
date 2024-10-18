require("@rails/ujs").start()
require("turbolinks").start()
import './stylesheets/rdv_service_public';

import DsfrNewPassword from './components/dsfr-new-password.js';

document.addEventListener('turbolinks:load', DsfrNewPassword)
