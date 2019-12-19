require("@rails/ujs").start()
require("turbolinks").start()
require("chartkick")
require("chart.js")
import { PlacesInput } from 'packs/components/places-input.js';
import { Analytic } from 'packs/components/analytic.js';
import { Modal } from 'packs/components/modal';
import 'packs/components/browser-detection';
import 'select2/dist/js/select2.min.js';
import 'select2/dist/js/i18n/fr.js';
import 'packs/components/select2';
import 'bootstrap';

var analytic = new Analytic();
new Modal();

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
});
