require("@rails/ujs").start()
require("turbolinks").start()
require("chartkick")
require("chart.js")
import { PlacesInput } from 'packs/components/places-input.js';
import 'packs/components/analytic.js';
import { Modal } from 'packs/components/modal';
import 'packs/components/browser-detection';
import 'select2/dist/js/select2.min.js';
import 'select2/dist/js/i18n/fr.js';
import 'jquery-mask-plugin';
import 'packs/components/select2';
import 'packs/components/sentry';
import 'packs/components/search-form';
import 'bootstrap';

new Modal();

let setWhereInvalid = function (where, submit) {
  where.classList.remove("is-valid");
  where.classList.add("is-invalid");
  submit.disabled = true;
}

let setWhereValid = function (where, submit) {
  where.classList.add("is-valid");
  where.classList.remove("is-invalid");
  submit.disabled = false;
}

$(document).on('turbolinks:load', function() {
  $('input[type="tel"]').mask('00 00 00 00 00')
  Holder.run();
  let placeJsContainer = document.querySelector('.places-js-container');
  if (placeJsContainer !== null) {
    let placesInput = new PlacesInput(placeJsContainer);
    if (document.querySelector('#search_departement') !== null) {

      let where = document.querySelector('#search_where');
      let submit = document.querySelector('#search_submit');

      placesInput.on('change', function resultSelected(e) {
        let departement = (e.suggestion.postcode || '').substring(0, 2);
        $('#search_latitude').val(e.suggestion.latlng.lat)
        $('#search_longitude').val(e.suggestion.latlng.lng)
        document.querySelector('#search_departement').value = departement;
        if (departement.length == 2) {
          setWhereValid(where, submit);
        } else {
          setWhereInvalid(where, submit);
        }
      });

      placesInput.on('clear', function () {
        setWhereInvalid(where, submit);
      })
    }
  }
});
