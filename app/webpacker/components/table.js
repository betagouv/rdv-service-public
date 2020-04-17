function bindTableLinks() {
  const keycodes = { space: 32, enter: 13 }

  function visitDataUrl(event) {
    /** @type {HTMLTableRowElement} */
    const target = event.target.classList.contains("js-table-row")
      ? event.target
      : event.target.closest('.js-table-row')

    if (!target) {
      return
    }

    if (event.type === "click" ||
        event.keyCode === keycodes.space ||
        event.keyCode === keycodes.enter) {

      if (event.target.href) {
        return
      }

      const dataUrl = target.getAttribute("data-url")
      const selection = window.getSelection().toString()
      if (selection.length === 0 && dataUrl) {
        const delegate = target.querySelector(`[href="${dataUrl}"]`)
        if (delegate) {
          delegate.click()
        } else {
          window.location = dataUrl
        }
      }
    }
  }

  const tables = [...document.getElementsByTagName("table")]
  tables.forEach(
    /** @type {HTMLTableElement} */ (table) => {
    table.addEventListener("click", visitDataUrl)
    table.addEventListener("keydown", visitDataUrl)
  })
}

document.addEventListener("turbolinks:load", function() {
  bindTableLinks()
})
