class PopulateLibelle {

  constructor() {
    $(document).on('shown.rightbar', '.right-bar', function(e) {
      var serviceInput = $("#motif_service_id")
      if (serviceInput.val()) {
        get_motifs(serviceInput, $('#motif_name').data('value'))
      }
      serviceInput.change(() => {
        get_motifs(serviceInput)
      })
    })
  }
}

function get_motifs(serviceId, initialValue = null) {
  var serviceId = $("#motif_service_id").val()
  var motifInput = $('#motif_name')
  $.get(
    "/motif_libelles?service_id=" + serviceId,
    function (data) {
      console.log('service_id', serviceId, 'libelle', data.motif_libelles);
      motifInput.html('')
      motifInput.append(new Option('', ''));
      data.motif_libelles.forEach((e) => {
        if (initialValue) {
          var selected = motifInput.data('value') == e.name
        } else {
          var selected = false
        }
        motifInput.append(new Option(e.name, e.name, selected, selected));
      })
    }
  );
}

export { PopulateLibelle };
