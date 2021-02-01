class MotifFilters {
  constructor() {
    document.querySelectorAll('.js-motif-filters').forEach(formElt => {
      $(formElt).on('change', this.changeFilters)
    }
    )
  }

  changeFilters = () => {
    document.querySelector(".js-search-and-filter-form").submit()
  }
}

export { MotifFilters };

