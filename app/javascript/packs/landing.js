require("@rails/ujs").start()
require("turbolinks").start()

import { PlacesInput } from 'packs/components/places-input.js.erb';
import { Scroller } from 'packs/components/scroller';

import 'bootstrap';

$(document).on('turbolinks:load', function() {
  Holder.run();
  new PlacesInput(document.querySelector('.places-js-container'));
  new Scroller();
});