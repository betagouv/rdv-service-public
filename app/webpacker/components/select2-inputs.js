class Select2Inputs {
  constructor() {
    this.selector = '.select2-input'
    this.initInputs()
    $(document).on('turbolinks:load', this.initInputs)
    $(document).on('shown.bs.modal', '.modal', this.initInputs)
    $(document).on("turbolinks:before-cache", this.destroyInputs)
    $(document).on('select2:open', this.focusSearchInput)
  }

  focusSearchInput = (e) => {
    const selectId = e.target.id
    $(".select2-search__field[aria-controls='select2-" + selectId + "-results']").each(function (key,value,) {
      value.focus()
    })
  }

  initInputs = () => {
    document.querySelectorAll(this.selector).forEach(this.initInput)
  }

  initInput = (elt) => $(elt).select2(this.getInputOptions(elt))

  getInputOptions = elt => {
    let options = {}
    if (elt.dataset.selectOptions !== undefined)
      options = JSON.parse(elt.dataset.selectOptions)
    if (options.disableSearch)
      options.minimumResultsForSearch = Infinity // cf https://select2.org/searching
    return options
  }

  destroyInputs = () => {
    if ($(this.selector).first().data('select2') != undefined)
      $(this.selector).select2('destroy')
  }
}

export { Select2Inputs };
