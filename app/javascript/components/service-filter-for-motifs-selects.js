class ServiceFilterForMotifsSelects {
  // jQuery is required to interact with select2

  constructor() {
    $(document).on("DOMContentLoaded", this.initFilter)
  }

  initFilter = () => {
    this.serviceSelect = document.querySelector(".js-service-filter")
    this.motifSelect = document.querySelector('.js-filtered-motifs')
    if (!this.serviceSelect || !this.motifSelect) return

    this.initialGroupedOptions = this.getInitialGroupedOptions()
    $(this.serviceSelect).on("change", () => this.refreshData())
    $(this.serviceSelect).trigger("change")
  }

  destroyFilter = () => {
    this.motifSelect = document.querySelector('.js-filtered-motifs')
    if (!this.motifSelect) return

    this.motifSelect.dataset.valueBeforeDestroy = $(this.motifSelect).val()
    $(this.motifSelect).select2("destroy")
  }

  // select2 expects format {groupname: [{id: "optvalue", text: "opttext"}, ...]}
  getInitialGroupedOptions = () =>
    Array.
      from(this.motifSelect.querySelectorAll("optgroup")).
      map(this.formatOptgroup)

  formatOptgroup = (g) => ({ text: g.label, children: this.optgroupChildren(g) })

  optgroupChildren = optgroup =>
    Array.
      from(optgroup.querySelectorAll("option")).
      map(this.formatOption)

  formatOption = (option) => ({id: option.value, text: option.innerHTML})

  refreshData = () => {
    const currentServiceName = this.serviceSelect.options[this.serviceSelect.selectedIndex].text
    const filteredOptions = this.getFilteredGroupedOptions(currentServiceName)
    const motifValue = $(this.motifSelect).val() || this.motifSelect.dataset.valueBeforeDestroy
    const filteredOptionsWithSelected = this.tagSelectedOption(filteredOptions, motifValue)
    const filteredOptionsWithBlank = [{id: "", text: ""}].concat(filteredOptionsWithSelected)
    $(this.motifSelect).html("") // otherwise it doesn't clear previous options
    $(this.motifSelect).select2({ data: filteredOptionsWithBlank })

    if (filteredOptionsWithSelected.length == 1 && filteredOptionsWithSelected[0].children.length == 1) {
      this.autoselectFirstMotif();
    }
  }

  autoselectFirstMotif = () => {
    const options = this.motifSelect.querySelectorAll("option")
    options[1].selected = true
    $(this.motifSelect).trigger("change")
  }

  getFilteredGroupedOptions = (serviceName) =>
    serviceName ? this.initialGroupedOptions.filter(g => g.text == serviceName) : this.initialGroupedOptions

  tagSelectedOption = (optgroups, value) =>
    optgroups.map(optgroup => ({
      ...optgroup,
      children: optgroup.children.map(opt => ({ selected: opt.id == value, ...opt })),
    }))
}

export { ServiceFilterForMotifsSelects }
