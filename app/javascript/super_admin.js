import "@hotwired/turbo-rails";

// Nous ne souhaitons pas utiliser Turbo Drive (voir #4790 et #5917)
Turbo.session.drive = false

import { PlacesInputs } from './components/places-inputs.js';

document.addEventListener("DOMContentLoaded", function() {
  new PlacesInputs();
});

import "./stylesheets/components/_autocomplete.scss";
import "./stylesheets/components/_rdv_solidarites_instance_name.scss";
