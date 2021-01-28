class MotifFilters {
  constructor() {
    document.querySelectorAll('.motif-filters').forEach(formElt =>
      formElt.addEventListener('change', this.changeFilters)
    )
  }

  changeFilters = () => {
    ["service", "online", "location_type"].forEach(function (field) {
      document.querySelector(`#${field}_filter`).value = document.querySelector(`#${field}_filter_select`).value
    })
    document.querySelector(".search-and-filter-form").submit()
  }
}

export { MotifFilters };

