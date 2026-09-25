export default () => {
  document.querySelectorAll('.js-rdv-invitation-user-picker').forEach(elt => {
    const select = $(elt.querySelector(".js-rdv-invitation-user-picker__select"))
    const form = elt.querySelector(".js-rdv-invitation-user-picker__form")


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
      form.querySelector("input#rdv_plan_user_id").value = e.params.data.id
      form.submit()
    })
  });
}
