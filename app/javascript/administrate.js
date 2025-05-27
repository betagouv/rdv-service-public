require("@rails/ujs").start()
require("turbolinks").start()

import "./stylesheets/administrate/application";

import 'select2/dist/js/select2.min.js';

$(document).on('turbolinks:load', function() {
  $(".field-unit--has-many select").select2({theme: "bootstrap4"})
});
