import 'packs/components/table'
import 'packs/components/date_time_picker'
import 'selectize'

$(document).on('turbolinks:load', function() {
  $(".field-unit--has-many select").selectize({});
});