//
// This ClipboardController allows you to copy a value in the browser's clipboard.
// We'd love to use the clipboard directly, asking for the permission first, but it keeps raising a
// "DOMException: Document is not focused" error on chromium browsers, so we have to use the old "execCommand" method 
// for now.
// https://developer.mozilla.org/en-US/docs/Web/API/Permissions_API
// https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Interact_with_the_clipboard
//
// This is using Stimulus-style data attributes for targets, in the hope we modernize our js stack.

class ClipboardController {
  constructor(container) {
    this.container = container
    this.setupTargets()
    this.setupActions()
  }

  setupTargets() {
    this.inputToCopy = this.container.querySelector('[data-clipboard-target="input-to-copy"]')
    this.copyButton = this.container.querySelector('[data-clipboard-target="copy-button"]')
  }

  setupActions() {
    this.copyButton.addEventListener('click', e => { this.copyToClipboard(e) })
  }

  copyToClipboard(e) {
    this.inputToCopy.select()
    document.execCommand('copy')
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
