class RdvStatusDropdown {
  constructor(dropdownElt) {
    this.currentStatusElt = dropdownElt.querySelector(".js-current-status")
    dropdownElt.querySelectorAll('.js-change-link').forEach(changeLinkElt => {
      changeLinkElt.addEventListener('ajax:before', this.statusWillChange)
      changeLinkElt.addEventListener('ajax:success', this.statusChanged)
    })
  }

  statusWillChange = () => {
    this.currentStatusElt.innerHTML = "..."
    this.currentStatusElt.setAttribute("disabled", "disabled")
    this.changeRdvStatusClass()
  }

  statusChanged = event => {
    const rdv = event.detail[0].rdv
    if (!rdv) return
    // happens when authorize fails, UJS + Turbolinks auto-reloads, but doesn't
    // detach callbacks
    this.currentStatusElt.innerHTML = rdv.temporal_status_human
    this.currentStatusElt.removeAttribute("disabled")
    this.changeRdvStatusClass(rdv.status)
  }

  changeRdvStatusClass = (newStatus = null) => {
    Array.from(this.currentStatusElt.classList)
      .filter(e => e.match(/rdv-status-.*/))
      .forEach(cl => this.currentStatusElt.classList.remove(cl))
    if (newStatus) this.currentStatusElt.classList.add(`rdv-status-${newStatus}`)
  }
}

class RdvStatusDropdowns {
  constructor() {
    document
      .querySelectorAll('.js-rdv-status-dropdown')
      .forEach(elt => new RdvStatusDropdown(elt))
  }
}

export { RdvStatusDropdowns };
