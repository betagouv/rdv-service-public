//
// This ClipboardController allows you to copy a value in the browser's clipboard.
// This is using Stimulus-style data attributes for targets, in the hope we modernize our js stack.

class ClipboardController {
  constructor(container) {
    this.container = container
    this.setupValues()
    this.setupTargets()
    this.setupActions()
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
