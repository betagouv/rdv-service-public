class MergeUsersForm {
  constructor() {
    // have to use jQuery here because of select2
    $(".js-merge-users-user-select").on("change", this.userSelected)
    $(".js-merge-users-collapse-user").on("click", this.toggleDisabledUserFields)
  }

  userSelected = (event) => {
    const urlSearchParams = new URLSearchParams(window.location.search)
    urlSearchParams.set(event.currentTarget.dataset.fieldName, event.currentTarget.value)
    window.location = `${window.location.pathname}?${urlSearchParams}`
  }

  toggleDisabledUserFields = (evt) => {
    const parentElt = $(evt.currentTarget).closest(".js-merge-users-user-wrapper")
    parentElt.find("select.js-selectable").removeAttr("disabled")
  }
}

export { MergeUsersForm }
