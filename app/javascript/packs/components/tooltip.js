function initTooltip() {
  $(function () {
    $('[data-toggle="tooltip"]').tooltip()
  })
}

$(document).on('turbolinks:load', function() {
  initTooltip();
});

$(document).on('shown.rightbar', '.right-bar', function(e) {
  initTooltip();
});
