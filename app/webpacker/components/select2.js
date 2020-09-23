function initSelect2() {
  $(".select2-input").each(function () {
    const options = this.dataset.selectOptions !== undefined ? JSON.parse(this.dataset.selectOptions) : {};
    if (options.disableSearch)
      options.minimumResultsForSearch = Infinity // cf https://select2.org/searching
    $(this).select2(options);
  });
}

$(document).on('turbolinks:load', function() {
  initSelect2();
});

$(document).on('shown.bs.modal', '.modal', function(e) {
  initSelect2();
});

$(document).on('shown.rightbar', '.right-bar', function(e) {
  initSelect2();
});

$(document).on("turbolinks:before-cache", function() {
  $('.select2-input').select2('destroy');
});

export { initSelect2 };
