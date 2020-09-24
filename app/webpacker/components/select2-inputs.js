class Select2Inputs {
  constructor() {
    this.selector = '.select2-input'
    this.initInputs()
    $(document).on('turbolinks:load', this.initInputs)
    $(document).on('shown.bs.modal', '.modal', this.initInputs)
    $(document).on('shown.rightbar', '.right-bar', this.initInputs)
    $(document).on("turbolinks:before-cache", this.destroyInputs)
  }

  initInputs = () =>
    document.querySelectorAll(".select2-input").forEach(this.initInput)

  initInput = (elt) => $(elt).select2(this.getInputOptions(elt))

  getInputOptions = elt => {
    let options = {}
    if (elt.dataset.selectOptions !== undefined)
      options = JSON.parse(elt.dataset.selectOptions)
    if (options.disableSearch)
      options.minimumResultsForSearch = Infinity // cf https://select2.org/searching
    return options
  }


  destroyInputs = () => $(this.selector).select2('destroy')
}

export { Select2Inputs };
