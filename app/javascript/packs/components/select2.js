$(document).on('turbolinks:load', function() {
  $(".select2-input").select2({
    theme: "bootstrap4"
  });
});

$(document).on("turbolinks:before-cache", function() {
  $('.select2-input').select2('destroy');
});
