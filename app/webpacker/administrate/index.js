import 'selectize'

import '../components/table'
import '../components/date_time_picker'
import { PlacesInput } from '../components/places-input.js';

$(document).on('turbolinks:load', function() {
  $(".field-unit--has-many select").selectize({});
  new PlacesInput(document.querySelector('.places-js-container'));
});
