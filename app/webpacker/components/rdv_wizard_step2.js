class RdvWizardStep2 {

  constructor() {
    if (!$('.js-new-rdv-users-select').length) { return; }

    const canonicalUrlStr = document.querySelector("input[name=js-canonical-path]").value
    this.canonicalUrl = new URL(canonicalUrlStr, window.location)
    this.urlSearchParams = new URLSearchParams(this.canonicalUrl.search.substr(1))
    this.organisationId = $("input.js-current-organisation-id").val()
    $('.js-new-rdv-users-select').on('select2:select', (e) => {
      this.showSpinner()
      this.urlSearchParams.append("user_ids[]", e.params.data.id)
      this.redirectToNewUrl()
    });
    this.attachRemoveUserListeners()
    $(".js-toggle-add-user-interface").on('click', (e) => {
      e.preventDefault()
      $(".js-add-user-interface").removeClass("d-none")
      $(e.currentTarget).remove()
    })

    $('js-toggle-add-user-interface').on('click', e => {
      $('js-toggle-add-user-interface').addClass('d-none')
      $('js-add-user-interface').removeClass('d-none')
    })
  }

  attachRemoveUserListeners = () => {
    $('.js-remove-user').click(event => {
      this.showSpinner()
      const userId = event.currentTarget.getAttribute('data-user-id')
      let userIds = this.urlSearchParams.getAll("user_ids[]")
      userIds.splice(userIds.indexOf(userId), 1)
      this.urlSearchParams.delete("user_ids[]")
      userIds.forEach(id => this.urlSearchParams.append("user_ids[]", id))
      this.redirectToNewUrl()
    });
  }

  showSpinner = () => {
    $(".js-users-spinner").removeClass("d-none")
  }

  redirectToNewUrl = () => {
    this.canonicalUrl.search = this.urlSearchParams.toString();
    window.location = this.canonicalUrl;
  }
}

export { RdvWizardStep2 };
