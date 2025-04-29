require("@rails/ujs").start()
require("turbolinks").start()

import "./stylesheets/administrate/application";

import 'select2/dist/js/select2.min.js';
import { Select2Inputs } from './components/select2-inputs'
import { PlacesInputs } from './components/places-inputs.js';

$.fn.select2.defaults.set("theme", "bootstrap4")
$.fn.select2.defaults.set("language", "fr")

new Select2Inputs()

$(document).on('turbolinks:load', function() {
  new PlacesInputs();
  $(".field-unit--has-many select").select2({theme: "bootstrap4"})
});
