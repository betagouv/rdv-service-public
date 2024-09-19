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

  initInput = (elt) => {
    const config = this.getInputConfig(elt)
    $(elt).select2(config)
    if (elt.dataset.autoSelectSoleOption) {
      this.autoSelectSoleOption(elt, config)
    }
  }

  getInputConfig = elt => {
    let config = {}
    if (elt.dataset.select2Config !== undefined)
      config = JSON.parse(elt.dataset.select2Config)

    if (config.disableSearch)
      config.minimumResultsForSearch = Infinity // cf https://select2.org/searching

    // Make sure select2 works correctly inside a modal
    // https://select2.org/troubleshooting/common-problems#select2-does-not-function-properly-when-i-use-it-inside-a-bootst
    let modal = $(elt).closest(".modal")[0]
    if (modal !== undefined)
      config.dropdownParent = modal

    // Lorsque le select est configuré en AJAX **et** qu'aucune <option> n'est pré-injectée dans le HTML,
    // l'utilisateur⋅ice voit seulement un champ de recherche et une mention "Aucun résultat trouvé".
    // Afin d'indiquer clairement qu'il est attendu de commencer à saisir quelque-chose, ce code fait en
    // sorte que la mention soit plutot "Commencez à taper pour rechercher".
    const isAjax = elt.dataset.select2Config?.includes("ajax");
    const hasAnyOption = Array.from(elt.options).some(opt => opt.value); // we rule out options without value, they are usually placeholders
    if (isAjax && !hasAnyOption) {
      config.minimumInputLength = 1
      config.language = { inputTooShort: () => "Commencez à taper pour rechercher" } // Overrides select2/i18n/fr.js
    }

    return config
  }

  destroyInputs = () => {
    if ($(this.selector).first().data('select2') != undefined)
      $(this.selector).select2('destroy')
  }

  autoSelectSoleOption = (elt, options) => {
    // This code checks if a select element (represented by the `elt` variable) has only one option.
    // return all options if it is ajax
    const isAjax = elt.dataset.select2Config?.includes("ajax");
    if (isAjax) return;

    // Get all options and remove blank values if exists (placeholders)
    const optionsList = $(elt).find("option").filter(function() {
      return $(this).val() !== "";
    });
    if (optionsList.length === 1) {
      // if one option is already selected, return
      if ($(elt).val() === optionsList.val()) return;
      // Otherwise, set the value of the select element to the value of its sole option and trigger a change event on it.
      $(elt).val(optionsList.val()).trigger('change');
    }
  }
}

export { Select2Inputs };
