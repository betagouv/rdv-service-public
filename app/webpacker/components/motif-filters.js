class MotifFilters {
  constructor() {
    document.querySelectorAll('.motif-filters').forEach(formElt =>
      formElt.addEventListener('change', this.changeFilters)
    )
  }

  changeFilters = () => {
    document.querySelector("#service_filter").value = document.querySelector("#service_filter_select").value
    document.querySelector("#online_filter").value = document.querySelector("#online_filter_select").value
    document.querySelector("#location_type_filter").value = document.querySelector("#location_type_filter_select").value
    document.querySelector(".search-and-filter-form").submit()
  }
}

export { MotifFilters };

