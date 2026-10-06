document.documentElement.addEventListener("turbo:load", () => window.Turbo.session.drive = false)

import { PlacesInputs } from './components/places-inputs.js';
import setupCopyEmailButtons from './super_admin/copy_email_button.js'

document.addEventListener("DOMContentLoaded", function() {
  new PlacesInputs();
  setupCopyEmailButtons();
});

import "./stylesheets/components/_autocomplete.scss";
import "./stylesheets/components/_rdv_solidarites_instance_name.scss";
import "./stylesheets/components/_copy_email_button.scss";
