import 'whatwg-fetch'

class RecordVersions {

  constructor() {
    if (window.location.hash != "#history") return;

    this.loaded = false;
    this.displayed = false;

    this.titleTarget = document.querySelector('.js-record-versions-toggle')
    this.bodyTarget = document.querySelector('.js-record-versions-body')
    if (!this.titleTarget || !this.bodyTarget) return;

    this.titleTarget.addEventListener('click', this.toggle)
    this.toggle()
  }

  toggle = (event) => {
    if (event) { event.preventDefault() }
    this.displayed = !this.displayed
    const textKey = this.displayed ? "close" : "open"
    this.titleTarget.textContent = this.titleTarget.getAttribute(`data-text-${textKey}`)
    $(this.bodyTarget).collapse(this.displayed ? "show" : "hide")
    if (!this.loaded && this.displayed) {
      fetch(this.titleTarget.dataset.versionsUrl)
        .then(res => res.text())
        .then(text => {
          this.bodyTarget.innerHTML = text
          this.loaded = true
        })
    }
    history.replaceState(null, null, this.displayed ? "#history" : "#")
  }
}

export { RecordVersions }
