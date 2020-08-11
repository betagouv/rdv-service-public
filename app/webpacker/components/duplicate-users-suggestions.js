class DuplicateUsersSuggestions {
  constructor() {
    const $button = $(".js-load-more-duplicate-users-suggestions")
    if (!$button) return

    this.bindHandlers()
  }

  bindHandlers = () => {
    $(".js-load-more-duplicate-users-suggestions")
      .on("ajax:success", this.displayResults)
  }

  displayResults = (event) => {
    const [_data, _status, xhr] = event.detail;
    $(event.currentTarget).
      closest(".js-load-more-duplicate-users-target").
      html(xhr.responseText)
    this.bindHandlers()
  }
}

export { DuplicateUsersSuggestions }
