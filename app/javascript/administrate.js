require("@rails/ujs").start()
import "@hotwired/turbo-rails"

// Nous ne souhaitons pas utiliser Turbo Drive (voir #4790 et #5917)
Turbo.session.drive = false

import "./stylesheets/administrate/application";

import 'select2/dist/js/select2';
import { PlacesInputs } from './components/places-inputs.js';

document.addEventListener("DOMContentLoaded", function() {
  new PlacesInputs();
  $(".field-unit--has-many select").select2({theme: "bootstrap4"})
});
