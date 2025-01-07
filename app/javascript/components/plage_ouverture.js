class PlageOuverture {
  constructor() {
    this.toggleLieuSelectionField(true);

    $(".plage-ouverture-form .form-check-input[name='plage_ouverture[motif_ids][]']").on("change", () => { this.toggleLieuSelectionField(); })

    // On veut aussi refresh le select de lieu lorsque l'on utilise le select-all.
    // L'événement js "input" est émis par '@stimulus-components/checkbox-select-all'.
    document.addEventListener("input", (e) => {
      if(e.target.dataset.checkboxSelectAllTarget === "checkboxAll") {
        // setTimeout permet d'évaluer l'état des checkboxes **après** que le select-all ait fait effet
        setTimeout(this.toggleLieuSelectionField)
      }
    })
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
