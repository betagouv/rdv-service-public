require("@rails/ujs").start()
require("turbolinks").start()

import { PlacesInput } from 'packs/components/places-input.js.erb';
import { Analytic } from 'packs/components/analytic.js.erb';
import 'packs/components/browser-detection';
import 'select2/dist/js/select2.min.js';
import 'bootstrap';

var analytic = new Analytic();

$(document).on('turbolinks:load', function() {
  analytic.trackPageView();
  Holder.run();
  let placeJsContainer = document.querySelector('.places-js-container');
  if (placeJsContainer !== null) {
    let placesInput = new PlacesInput(placeJsContainer);
    if (document.querySelector('#search_departement') !== null) {
      placesInput.on('change', function resultSelected(e) {
        document.querySelector('#search_departement').value = (e.suggestion.postcode || '').substring(0, 2);
      });
    }

  }
  $(".select2-input").select2({
    theme: "bootstrap4"
  });
});
