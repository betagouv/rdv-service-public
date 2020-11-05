class SectorAttributionForm {
  constructor() {
    this.formElt = document.querySelector('.js-sector-attribution-form')
    if (!this.formElt) return

    this.spinnerOverlayElt = document.querySelector(".js-spinner-overlay")
    this.$organisationSelect = $(this.formElt).find('select[name="sector_attribution[organisation_id]"]')

    this.formElt.
      querySelectorAll('input[name="sector_attribution[level]"]').
      forEach(i => i.addEventListener("change", this.onLevelChange))
    this.$organisationSelect.on("change", this.onOrganisationChange)
  }

  onLevelChange = (event) =>
    this.changeGetParamAndRefresh("level", event.currentTarget.value)

  onOrganisationChange = (event) => {
    if (this.getSelectedLevel() == "agent")
      this.changeGetParamAndRefresh("organisation_id", this.$organisationSelect.val())
  }

  changeGetParamAndRefresh = (name, value) => {
    const urlSearchParams = new URLSearchParams(window.location.search)
    urlSearchParams.set(name, value)
    this.displaySpinner()
    window.location = `${window.location.pathname}?${urlSearchParams}`
  }

  getSelectedLevel = () =>
    this.formElt.
      querySelector('input[name="sector_attribution[level]"]:checked').
      value

  displaySpinner = () => this.spinnerOverlayElt.classList.remove("d-none")
}

export { SectorAttributionForm };
