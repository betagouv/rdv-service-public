class NameInitialsForm {
  constructor() {
    this.formElt = document.querySelector('.js-name-initials-form');
    if (!this.formElt) return

    this.inputElts = this.formElt.querySelectorAll('input[type="text"]')
    this.inputElts[0].focus()
    this.inputElts.forEach(elt => elt.addEventListener("input", this.onInputChange))
    this.inputElts.forEach(elt => elt.addEventListener("keyup", this.onKeyUpChange))
    this.inputElts.forEach(elt => elt.addEventListener("keydown", this.onKeyDownChange))
  }

  onInputChange = (event) => {
    const inputElt = event.currentTarget
    inputElt.value = inputElt.value.toUpperCase()
    const idx = [...this.inputElts].indexOf(inputElt)
    if (inputElt === this.inputElts[this.inputElts.length - 1]) {
      return this.formElt.submit()
    }
    if (inputElt.value !== "") {
      return this.inputElts[idx + 1].focus()
    }
  }

  onKeyUpChange = (event) => {
    const inputElt = event.currentTarget
    const idx =  [...this.inputElts].indexOf(inputElt)
    if (event.key === "Backspace" && idx !== 0 && this.inputValues[idx] === "") {
      return this.inputElts[idx - 1].focus()
    }
  }

  onKeyDownChange = (event) => {
    this.inputValues = [...this.inputElts].map(elt => elt.value)
  }
}

export { NameInitialsForm };
