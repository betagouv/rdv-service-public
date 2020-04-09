import 'packs/components/table'
import 'packs/components/date_time_picker'
import 'selectize'
import { PlacesInput } from 'packs/components/places-input.js';

$(document).on('turbolinks:load', function() {
  $(".field-unit--has-many select").selectize({});
  new PlacesInput(document.querySelector('.places-js-container'));
});
