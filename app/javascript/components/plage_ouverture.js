class PlageOuverture {
  constructor() {
    this.toggleLieuSelectionField(true);
    $(".plage-ouverture-form .form-check-input[name='plage_ouverture[motif_ids][]']").on("input", () => { this.toggleLieuSelectionField(); });
    this.armSecondaryTimesToggle();
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

  armSecondaryTimesToggle() {
    const addSecondaryTimesButton = document.querySelector(".js-plages-form-add-secondary-times-button")
    const removeSecondaryTimesButton = document.querySelector(".js-plages-form-remove-secondary-times-button")
    const secondaryTimesContainer = document.querySelector(".js-plages-form-secondary-times-container")
    const secondaryTimesShownInitially = document.querySelector(".js-plages-form-secondary-times-initial-state").dataset.state === "true"

    const secondaryTimesStartsAtHours = document.querySelector("#plage_ouverture_secondary_start_time_4i")
    const secondaryTimesStartsAtMinutes = document.querySelector("#plage_ouverture_secondary_start_time_5i")
    const secondaryTimesEndsAtHours = document.querySelector("#plage_ouverture_secondary_end_time_4i")
    const secondaryTimesEndsAtMinutes = document.querySelector("#plage_ouverture_secondary_end_time_5i")

    const primaryTimesEndsAtHours = document.querySelector("#plage_ouverture_end_time_4i")

    const showSecondaryTimes = () => {
      addSecondaryTimesButton.classList.add("hidden")
      removeSecondaryTimesButton.classList.remove("hidden")
      secondaryTimesContainer.classList.remove("hidden")

      secondaryTimesStartsAtHours.required = true
      secondaryTimesStartsAtMinutes.required = true
      secondaryTimesEndsAtHours.required = true
      secondaryTimesEndsAtMinutes.required = true

      if(!secondaryTimesStartsAtHours.value) {
        secondaryTimesStartsAtHours.value ||= parseInt(primaryTimesEndsAtHours.value) + 1
        secondaryTimesStartsAtMinutes.value ||= "00"
        secondaryTimesEndsAtHours.value ||= parseInt(primaryTimesEndsAtHours.value) + 5
        secondaryTimesEndsAtMinutes.value ||= "00"
      }
    }
    const hideSecondaryTimes = () => {
      addSecondaryTimesButton.classList.remove("hidden")
      removeSecondaryTimesButton.classList.add("hidden")
      secondaryTimesContainer.classList.add("hidden")

      secondaryTimesStartsAtHours.required = false
      secondaryTimesStartsAtMinutes.required = false
      secondaryTimesEndsAtHours.required = false
      secondaryTimesEndsAtMinutes.required = false

      secondaryTimesStartsAtHours.value = ""
      secondaryTimesStartsAtMinutes.value = ""
      secondaryTimesEndsAtHours.value = ""
      secondaryTimesEndsAtMinutes.value = ""
    }
    addSecondaryTimesButton.addEventListener("click", showSecondaryTimes)

    removeSecondaryTimesButton.addEventListener("click", hideSecondaryTimes)

    if(secondaryTimesShownInitially) {
      showSecondaryTimes()
    }
  }
}

export { PlageOuverture };
