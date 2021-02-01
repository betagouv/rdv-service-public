class MotifFilters {
  constructor() {
    console.log("dans le motif filters constructor")
    document.querySelectorAll('.motif-filters').forEach(formElt => {
      $(formElt).on('change', this.changeFilters)
    }
    )
  }

  changeFilters = () => {
    document.querySelector(".search-and-filter-form").submit()
  }
}

export { MotifFilters };

