class RdvWizardStep2 {

  constructor() {
    if (!$('.js-new-rdv-users-select').length) { return; }

    this.canonicalUrlStr = document.querySelector("input[name=js-canonical-path]").value;

    this.attachAddUserListener()
    this.attachToggleAddUserInterface()
  }

  getCanonicalUrl = () => new URL(this.canonicalUrlStr, window.location)

  getCanonicalUrlSearchParams = () =>
    new URLSearchParams(this.getCanonicalUrl().search.substr(1))

  attachAddUserListener = () => {
    $('.js-new-rdv-users-select').on('select2:select', (e) => {
      this.showSpinner()
      const urlSearchParams = this.getCanonicalUrlSearchParams()
      urlSearchParams.append("user_ids[]", e.params.data.id)
      this.redirectToUrlWithSearchParams(urlSearchParams)
    });
  }

  attachToggleAddUserInterface = () => {
    $(".js-toggle-add-user-interface").on('click', (e) => {
      e.preventDefault()
      $(".js-add-user-interface").removeClass("d-none")
      $(e.currentTarget).remove()
    })
  }

  showSpinner = () => {
    $(".js-users-spinner").removeClass("d-none")
  }

  redirectToUrlWithSearchParams = (urlSearchParams) => {
    const canonicalUrl = this.getCanonicalUrl()
    canonicalUrl.search = urlSearchParams.toString();
    window.location = canonicalUrl;
  }
}

export { RdvWizardStep2 };
