require("@rails/ujs").start()
import "@hotwired/turbo-rails"

// Nous ne souhaitons pas utiliser Turbo Drive (voir #4790 et #5917)
Turbo.session.drive = false

import 'select2/dist/js/select2.js';
import 'select2/dist/css/select2.css';
import { PlacesInputs } from './components/places-inputs.js';

document.addEventListener("DOMContentLoaded", function() {
  new PlacesInputs();
  // debugger;
  $(".field-unit--has-many select").select2()
});

import "./stylesheets/components/_autocomplete.scss";
import "./stylesheets/components/_rdv_solidarites_instance_name.scss";
