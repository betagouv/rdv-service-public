import 'selectize'

import '../components/table'
import { PlacesInputs } from '../components/places-inputs.js';

$(document).on('turbolinks:load', function() {
  $(".field-unit--has-many select").selectize({});
  new PlacesInputs();
});
