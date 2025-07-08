require("@rails/ujs").start()
// Nous souhaitons passer de Turbolinks à Turbo
// Dans un premier temps, nous ajoutons Turbo à l'application sans supprimer Turbolinks et nous désactivons le drive de Turbo.
// Cela nous permet d’utiliser les Turbo Streams et les Turbo Frames pour pouvoir supprimer l’usage des js.erb.
// Dans un second temps, nous supprimerons Turbolinks et nous activerons le drive de Turbo.
require("turbolinks").start()
import "@hotwired/turbo-rails"
Turbo.session.drive = false

import "./stylesheets/administrate/application";

import 'select2/dist/js/select2.min.js';
import { PlacesInputs } from './components/places-inputs.js';

$(document).on('turbolinks:load', function() {
  new PlacesInputs();
  $(".field-unit--has-many select").select2({theme: "bootstrap4"})
});
