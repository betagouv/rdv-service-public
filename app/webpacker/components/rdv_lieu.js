//
// In Admin::RdvWizardStepsController#step3, switch between a select to pick an existing Lieu
// or fields for a new single-use Lieu
// This is using Stimulus-style data attributes for targets, in the hope we modernize our js stack.

class RdvLieuController {
  constructor(container) {
    this.container = container
    this.setupTargets();
    this.setupActions();

    if(this.container.dataset.initialState === "single_use") {
      this.showNewLieuFields()
    } else {
      this.showExistingLieuSelect()
    }
  }

  setupTargets() {
    this.existingLieuSelect = this.container.querySelector('[data-rdv-lieu-target="existing_lieu_select"]');
    this.existingLieuLink = this.container.querySelector('[data-rdv-lieu-target="select_lieu_link"]');
    this.newLieuLink = this.container.querySelector('[data-rdv-lieu-target="new_lieu_link"]');
    this.newLieuFieldset = this.container.querySelector('[data-rdv-lieu-target="new_lieu_fieldset"]');

    // The placeholder is displayed by select2, which doesn’t make it easy to change via API; let's just dig to the element.
    // Even then, this may fail in some situations where no placeholder is set, for example when loading the form with a preselected value.
    this.selectPlaceholderTarget = this.container.querySelector(".select2-selection__placeholder")
  }

  setupActions() {
    this.newLieuLink.addEventListener('click', e => { e.preventDefault(); this.showNewLieuFields() } );
    this.existingLieuLink.addEventListener('click', e => { e.preventDefault(); this.showExistingLieuSelect() } );
  }

  showExistingLieuSelect() {
    this.newLieuLink.hidden = false;
    this.existingLieuSelect.disabled = false;

    this.newLieuFieldset.hidden = true;
    this.newLieuFieldset.disabled = true;

    if(this.selectPlaceholderTarget !== null) {
      this.selectPlaceholderTarget.textContent = this.container.dataset.selectPlaceholderExistingLieu;
    }
  }

  showNewLieuFields(event) {
    this.newLieuLink.hidden = true;
    this.existingLieuSelect.disabled = true;

    this.newLieuFieldset.hidden = false;
    this.newLieuFieldset.disabled = false;

    if(this.selectPlaceholderTarget !== null) {
      this.selectPlaceholderTarget.textContent = this.container.dataset.selectPlaceholderSingleUseLieu;
    }
  }
}

class RdvLieu {
  constructor() {
    document.querySelectorAll('[data-controller="rdv-lieu"]').forEach(elt => new RdvLieuController(elt))
  }
}

export { RdvLieu };
