document.documentElement.addEventListener("turbo:load", () => window.Turbo.session.drive = false)

import { PlacesInputs } from './components/places-inputs.js';

document.addEventListener("DOMContentLoaded", function() {
  new PlacesInputs();
});

import "./stylesheets/components/_autocomplete.scss";
import "./stylesheets/components/_rdv_solidarites_instance_name.scss";
