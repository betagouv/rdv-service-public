class DsfrAlert {
  constructor() {
    this.closeButtons = document.querySelectorAll('.js-dsfr-alert-close-button')
    if (this.closeButtons.length == 0) return

    this.closeButtons.forEach(elt => elt.addEventListener("click", this.close))
  }

  close = (event) => {
    event.preventDefault();

    const closeButtonElt = event.currentTarget
    const parentElt = closeButtonElt.parentElement
    if (!Array.from(parentElt.classList).includes("fr-alert")) {
      console.warn("could not close dsfr-alert")
      return false
    }

    parentElt.remove()
    return false
  }
}

export { DsfrAlert };
