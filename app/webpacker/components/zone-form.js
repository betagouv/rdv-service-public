class ZoneForm {
  constructor() {
    this.formElt = document.querySelector('.js-zone-form')
    if (!this.formElt) return

    this.canonicalPath = this.formElt.dataset.canonicalPath
    this.spinnerOverlayElt = document.querySelector(".js-spinner-overlay")
    this.formElt.
      querySelectorAll('input[name="zone[level]"]').
      forEach(i => i.addEventListener("change", this.onLevelChange))
  }

  onLevelChange = (event) =>
    this.changeGetParamAndRefresh("level", event.currentTarget.value)

  changeGetParamAndRefresh = (name, value) => {
    const urlSearchParams = new URLSearchParams(window.location.search)
    urlSearchParams.set(name, value)
    this.displaySpinner()
    window.location = `${this.canonicalPath}?${urlSearchParams}`
  }

  displaySpinner = () => this.spinnerOverlayElt.classList.remove("d-none")
}

export { ZoneForm };
