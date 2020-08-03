import '../components/table'
import { PlacesInputs } from '../components/places-inputs.js';

$(document).on('turbolinks:load', function() {
  new PlacesInputs();
});
