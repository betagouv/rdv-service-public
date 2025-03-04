class PlageOuverture {
  constructor() {
    tiens_tiens_mais_cette_fonction_nexiste_pas();
    this.toggleLieuSelectionField(true);
    $(".plage-ouverture-form .form-check-input[name='plage_ouverture[motif_ids][]']").on("input", () => { this.toggleLieuSelectionField(); })
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
