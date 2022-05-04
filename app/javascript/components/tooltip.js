function initTooltip() {
  $(function () {
    $('[data-toggle="tooltip"]').tooltip()
  })
}

$(document).on('turbolinks:load', function() {
  initTooltip();
});

