/**
* A select2 adapater combining SingleSelction view
* and searchbox - replacing the view - when it needs to find and select another option
*/
$.fn.select2.amd.define("SearchableSingleSelection", [
  "select2/utils",
  "select2/selection/single",
  "select2/selection/eventRelay",
  "select2/dropdown/search"
],
function (Utils, SingleSelection, EventRelay, DropdownSearch) {
  var adapter = Utils.Decorate(SingleSelection, DropdownSearch);
  adapter = Utils.Decorate(adapter, EventRelay);

  adapter.prototype.render = function () {
    var $rendered = DropdownSearch.prototype.render.call(this, SingleSelection.prototype.render);

    this.$searchContainer.hide();
    this.$element.siblings('.select2').find('.selection').prepend(this.$searchContainer);

    return $rendered;
  };

  var bindOrigin = adapter.prototype.bind;
  adapter.prototype.bind = function (container) {
    var self = this;

    bindOrigin.apply(this, arguments);

    container.on('open', function () {
      self.$selection.hide();
      self.$searchContainer.show();
    });

    container.on('close', function () {
      self.$searchContainer.hide();
      self.$selection.show();
    });
  };

  return adapter;
});

/*
* A select2 adapter to show simple dropdown list without a searchbox inside
*/
$.fn.select2.amd.define("UnsearchableDropdown", [
  "select2/utils",
  "select2/dropdown",
  "select2/dropdown/attachBody",
  "select2/dropdown/closeOnSelect"
],
function (Utils, Dropdown, AttachBody, CloseOnSelect) {
  var adapter = Utils.Decorate(Dropdown, AttachBody);
  adapter = Utils.Decorate(adapter, CloseOnSelect);
  return adapter;
});

$(document).on('turbolinks:load', function() {
  $('.select2-multiple').select2({
    placeholder: "test",
    data: [],
    language: "fr",
    theme: "bootstrap4",
    dropdownAutoWidth: true,
    width: '100%',
    selectionAdapter: $.fn.select2.amd.require("SearchableSingleSelection"),
    dropdownAdapter: $.fn.select2.amd.require("UnsearchableDropdown")
  })

  $('#search_service').on('change.select2', (e) => {
    var serviceId = e.target.value
    // Clear
    $('#search_motif.select2-multiple').find('option').remove().end()

    // Add Motifs
    console.log('hhklejljl');
    var placeholder = new Option("ex : Consultation médicale", '', false, false);
    $('#search_motif.select2-multiple').append(placeholder);
    console.log('cc');
    $.get(
      "/motif_libelles?service_id=" + serviceId,
      function (data) {
        data.motif_libelles.forEach((e) => {
          $('#search_motif.select2-multiple').append(new Option(e.name, e.name, false, false));
        })
      },
    )
  })
});

$(document).on("turbolinks:before-cache", function() {
  $('.select2-multiple').select2('destroy');
});
