class PlageOuverture {
  constructor() {
    this.toggleLieuSelectionField();

    let that = this;
    $(".plage-ouverture-form .form-check-input[name='plage_ouverture[motif_ids][]']").on("change", () => { that.toggleLieuSelectionField(); })
  }

  toggleLieuSelectionField() {
    let selectedMotifsPublicOffice = $(".plage-ouverture-form .form-check-input.public_office[name='plage_ouverture[motif_ids][]']:checked");

    if (selectedMotifsPublicOffice.length > 0) {
      $(".plage-ouverture-form .collapse.lieu-field").collapse("show");
    } else {
      $(".plage-ouverture-form .collapse.lieu-field .select2-input").val(null).trigger('change');
      $(".plage-ouverture-form .collapse.lieu-field").collapse("hide");
    }
  }
}

export { PlageOuverture };
