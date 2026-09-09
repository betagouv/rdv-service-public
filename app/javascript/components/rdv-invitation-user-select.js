export default () => {
  document.querySelectorAll('.js-rdv-invitation-user-select').forEach(elt => {
    $(elt).on('select2:select', (e) => {
      let url = new URL(window.location.href);
      url.searchParams.append("user_id", e.params.data.id);
      window.location.href = url;
    })
  });
}
