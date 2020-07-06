class AgentsCreneaux {
  constructor() {
    this.attachAllEventListeners()
  }

  attachAllEventListeners = () => {
    this.attachFormListeners()
    this.attachCollapserListeners()
  }

  attachFormListeners = () => {
    document.querySelectorAll('.js-creneaux-form').forEach(formElt =>
      formElt.addEventListener('ajax:success', this.attachAllEventListeners)
    )
  }

  attachCollapserListeners = () => {
    document.querySelectorAll('.js-collapse-toggler').forEach(elt =>
      elt.addEventListener('click', () => this.removeCollapsed(elt))
    )
  }

  removeCollapsed = (elt) => {
    $(elt).closest('.js-creneaux-list').removeClass("collapsed")
    elt.remove()
  }
}

export { AgentsCreneaux };
