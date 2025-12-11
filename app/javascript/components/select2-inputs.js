export const initializeSelect2 = () => {
  initInputs()
  document.addEventListener("DOMContentLoaded", initInputs)
  $(document).on("shown.bs.modal", ".modal", initInputs)
  $(document).on("select2:open", focusSearchInput)
};

export const SELECTOR = ".select2-input";

export const initInput = (elt) => {
  const config = getInputConfig(elt)
  $(elt).select2(config)
  if (elt.dataset.autoSelectSoleOption) {
    autoSelectSoleOption(elt, config)
  }
  // select2 change le comportement de l’événement change.
  // Pour pouvoir intercepter l’événement change, grâce à un data-action stimulus, il faut le re-déclencher manuellement.
  // On ne fait ceci que si il y a un data-action "change->" sur l'élément pour éviter des conflits (notamment avec le formulaire de fusion usagers).
  // cf https://psmy.medium.com/rails-6-stimulus-and-select2-de4a4d2b59e4
  $(elt).on("change", function () {
    const action = this.getAttribute("data-action") || "";
    if (action.includes("change->")) {
      let event = new Event("change");
      this.dispatchEvent(event);
    }
  });
};

const getInputConfig = (elt) => {
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
};

const autoSelectSoleOption = (elt, options) => {
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
    $(elt).val(optionsList.val()).trigger("change");
  }
};

const initInputs = () => {
  document.querySelectorAll(SELECTOR).forEach(initInput)
};

const destroyInputs = () => {
  if ($(SELECTOR).first().data("select2") != undefined)
    $(SELECTOR).select2("destroy")
};

const focusSearchInput = (e) => {
  const selectId = e.target.id
  $(".select2-search__field[aria-controls='select2-" + selectId + "-results']").each(function (key,value,) {
    value.focus()
  })
};
