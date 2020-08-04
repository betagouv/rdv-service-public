import '../components/table'
import 'select2/dist/js/select2.min.js';
import { PlacesInputs } from '../components/places-inputs.js';

$(document).on('turbolinks:load', function() {
  new PlacesInputs();
  $(".field-unit--has-many select").select2({theme: "bootstrap4"})
});
