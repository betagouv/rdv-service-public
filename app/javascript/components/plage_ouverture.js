class PlageOuverture {
  constructor() {
    this.toggleLieuSelectionField(true);
    $(".plage-ouverture-form .form-check-input[name='plage_ouverture[motif_ids][]']").on("change", () => { this.toggleLieuSelectionField(); })
  }

  toggleLieuSelectionField(noTransition = false) {
    const selectedMotifsPublicOffice = $(".plage-ouverture-form .form-check-input.public_office[name='plage_ouverture[motif_ids][]']:checked");
    const lieuSelectionField = $(".plage-ouverture-form .collapse.js-lieu-field").toggleClass("no-transition", noTransition);

    if (selectedMotifsPublicOffice.length > 0) {
      lieuSelectionField.collapse("show");
    } else {
      $(lieuSelectionField).find(".select2-input").val(null).trigger('change');
      lieuSelectionField.collapse("hide");
    }
  }
}

export { PlageOuverture };
