//
// This ClipboardController allows you to copy a value in the browser's clipboard.
// Asking for 'clipboard-write' permission isn't supported by Firefox or Safari as it is automatically granted,
// but we have to ask for it for Chrome and Edge.
// https://developer.mozilla.org/en-US/docs/Web/API/Permissions_API
// https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Interact_with_the_clipboard
// This is using Stimulus-style data attributes for targets, in the hope we modernize our js stack.

class ClipboardController {
  constructor(container) {
    this.container = container
    this.setupPermissions()
    this.setupValues()
    this.setupTargets()
    this.setupActions()
  }

  setupPermissions() {
    navigator.permissions
      .query({name:'clipboard-write'})
      .catch(_ => console.log("Asking for 'clipboard-write' permission not supported."))
  }

  setupValues() {
    this.toCopyValue = this.container.dataset.clipboardToCopyValue
  }

  setupTargets() {
    this.copyButton = this.container.querySelector('[data-clipboard-target="copy-button"]')
  }

  setupActions() {
    this.copyButton.addEventListener('click', e => { this.copyToClipboard(e) })
  }

  copyToClipboard(e) {
    navigator.clipboard.writeText(this.toCopyValue)
    alert("Lien copié dans le presse-papiers !")
    e.preventDefault()
  }
}

class Clipboard {
  constructor() {
    document.querySelectorAll('[data-controller="clipboard"]').forEach(elt => new ClipboardController(elt))
  }
}

export { Clipboard }
