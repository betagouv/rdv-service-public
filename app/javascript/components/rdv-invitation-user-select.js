export default () => {
  document.querySelectorAll('.js-rdv-invitation-user-select').forEach(elt => {
    // Les events de select2 ne semblent être utilisables que via le système d'events de jQuery, et pas avec un addEventListener normal
    $(elt).on('select2:select', (e) => {
      let url = new URL(elt.dataset["redirectUrl"]);
      url.searchParams.append("user_id", e.params.data.id);
      window.location.href = url;
    })
  });
}
