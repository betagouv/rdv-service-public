class AgentsCreneaux {
  constructor() {
    const formElt = document.querySelector('.js-creneaux-search-form')
    if (!formElt) return;

    formElt.addEventListener('ajax:success', this.attachEventListeners)
  }

  attachEventListeners = () => {
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
