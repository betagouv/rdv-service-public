class SelectUsersFromWizard {

  constructor() {
    this.urlSearchParams = new URLSearchParams(window.location.search.substr(1))
    this.organisationId = $("input[name=current_organisation]").val()
    $('.js-new-rdv-users-select').on('select2:select', (e) => {
      this.displayLoader()
      this.urlSearchParams.append("user_ids[]", e.params.data.id)
      window.location.search = this.urlSearchParams.toString();
    });
    this.attachRemoveUserListeners()
    $(".js-toggle-add-user-interface").on('click', (e) => {
      e.preventDefault()
      $(".js-add-user-interface").removeClass("d-none")
      $(e.currentTarget).remove()
    })
  }

  attachRemoveUserListeners = () => {
    $('.js-remove-user').click(event => {
      this.displayLoader();
      const userId = event.currentTarget.getAttribute('data-user-id')
      let userIds = this.urlSearchParams.getAll("user_ids[]")
      userIds.splice(userIds.indexOf(userId), 1)
      this.urlSearchParams.delete("user_ids[]")
      userIds.forEach(id => this.urlSearchParams.append("user_ids[]", id))
      window.location.search = this.urlSearchParams.toString();
    });
  }

  displayLoader = () => {
    $(".js-rdv-step-card").addClass("card-loading")
  }

}

export { SelectUsersFromWizard };
