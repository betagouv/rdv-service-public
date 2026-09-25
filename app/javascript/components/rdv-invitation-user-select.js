export default () => {
  document.querySelectorAll('.js-rdv-invitation-user-picker').forEach(elt => {
    const select = $(elt.querySelector(".js-rdv-invitation-user-picker__select"))

    const newUserBtn = elt.querySelector(".js-rdv-invitation-user-picker__new-user-btn")

    select.select2({
      dropdownCssClass: 'rdv-select-2--inline',
      minimumInputLength: 1,
      language:  {
        inputTooShort: () => "Commencez à taper pour chercher",
        noResults: () => "Aucun usager trouvé."
      },
      ajax: {
        url: select.data('url'),
        dataType: "json",
        delay: 250,
        processResults: function(data, params) {
          if (data.results.length == 0) {
            newUserBtn.classList.remove("fr-btn--tertiary-no-outline")
          } else {
            newUserBtn.classList.add("fr-btn--tertiary-no-outline")
          }
          return data
        }
      }
    })

    // Un hack pour s'assurer que le dropdown s'ouvre toujours vers le bas
    select.on("select2:open", function(e) {
      const dropdownElt = document.querySelector(".select2-dropdown--above")
      if (dropdownElt) {
        dropdownElt.classList.add('select2-dropdown--below');
        dropdownElt.classList.remove('select2-dropdown--above');
      }
    });

    select.select2('open')

    // Les events de select2 ne semblent être utilisables que via le système d'events de jQuery, et pas avec un addEventListener normal
    select.on('select2:select', (e) => {
      const form = elt.querySelector(".js-rdv-invitation-user-picker__form")

      form.querySelector("input#rdv_plan_user_id").value = e.params.data.id
      form.submit()
    })
  });
}
