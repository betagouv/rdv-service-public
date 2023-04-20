// Used in admin/motifs/_form.html.slim:
// the checkboxes created by simpleform have the classes “motif_for_secretariat” and “motif_bookable_publicly”
class MotifForm {

  toggleSecretariat() {
    const enabled = this.secretariatShouldBeEnabled();
    if (enabled == this.secretariatEnabled) return;

    if (!enabled) this.secretariatCheckbox.checked = false
    this.secretariatCheckbox.disabled = !enabled
    $(this.secretariatCheckbox).closest('.card').toggleClass('translucent', !enabled)

    this.secretariatEnabled = enabled
  }

  secretariatShouldBeEnabled() {
    return !document.querySelector("#motif_location_type_home:checked") &&
      !document.querySelector("#motif_follow_up:checked")
  }

  sectorisationShouldBeDisable() {
    return !document.querySelector("#motif_follow_up:checked") && !this.bookableByAgentsButton.checked
  }

  toggleSectorisation() {
    const enabled = this.sectorisationShouldBeDisable();
    if (enabled == this.sectorisationEnabled) return;

    if (!enabled) {
      document.querySelector('#motif_sectorisation_level_agent').checked = false
      document.querySelector('#motif_sectorisation_level_organisation').checked = false
      document.querySelector('#motif_sectorisation_level_departement').checked = true
    }
    document.
      querySelectorAll('input[name="motif[sectorisation_level]"]').
      forEach(i => i.disabled = !enabled)
    document.querySelector(".js-sectorisation-card").classList.toggle('hidden', !enabled)
    this.sectorisationEnabled = enabled
  }

  toggleOnlineSubFields() {
    const enabled = !this.bookableByAgentsButton.checked || this.motifCategoryIsSelected()
    document.querySelectorAll(".js-rdvs-editable").forEach(rdvEditableElement =>
      rdvEditableElement.classList.toggle('hidden', !enabled)
    )
  }

  toggleRdvsEditable() {
    const enabled = !this.bookableByAgentsButton.checked || this.motifCategoryIsSelected()
    document.querySelector("#motif_rdvs_editable_by_user").checked = enabled
  }

  showRdvInsertionDivs() {
    // Specifique RDV-I
    const hiddenDivsToShow = document.getElementsByClassName('rdv-insertion-divs-to-show');

    Array.from(hiddenDivsToShow).forEach(div => {
      div.style.display = this.motifCategoryIsSelected() ? 'inline-block' : 'none';
    });
  }

  hideRdvInsertionDivs() {
    // Specifique RDV-I
    const divsToHide = document.getElementsByClassName('rdv-insertion-divs-to-hide');

    Array.from(divsToHide).forEach(div => {
      div.style.display = this.motifCategoryIsSelected() ? 'none' : 'inline-block';
    });
  }

  toggleRdvInsertionFormChange() {
    this.showRdvInsertionDivs();
    this.hideRdvInsertionDivs();
    this.toggleOnlineSubFields();
    this.toggleRdvsEditable();
  }

  motifCategorySelect() {
    // Specifique RDV-I
    return document.getElementById('motif_motif_category_id');
  }

  motifCategoryIsSelected() {
    // Specifique RDV-I
    const selectedValue = this.motifCategorySelect()?.value;
    return (selectedValue != "") && (selectedValue != undefined)
  }

  constructor() {
    this.secretariatCheckbox = document.querySelector('#motif_for_secretariat')
    this.bookableByAgentsButton = document.querySelector('#motif_bookable_by_agents')
    if (!this.secretariatCheckbox || !this.bookableByAgentsButton) return;

    const noSecretariatInputs = ["input[name=\"motif[location_type]\"]", "input[name=\"motif[follow_up]\"]"]
    document.querySelectorAll(noSecretariatInputs).forEach(input =>
      input.addEventListener('change', e => this.toggleSecretariat())
    )
    const toggleSectorisationInputs = ["input[name=\"motif[sectorisation_level]\"]", "input[name=\"motif[follow_up]\"]"]
    document.querySelectorAll(toggleSectorisationInputs).forEach(input =>
      input.addEventListener('change', e => this.toggleSectorisation())
    )

    document.querySelectorAll('input[name="motif[bookable_by]"]').forEach(elt =>
      elt.addEventListener("change", evt => {
        if (document.querySelector(".js-sectorisation-card") !== null) { this.toggleSectorisation() }
        this.toggleOnlineSubFields()
        this.toggleRdvsEditable()
      })
    )

    this.toggleSecretariat()
    if (document.querySelector(".js-sectorisation-card") !== null) { this.toggleSectorisation() }
    this.toggleOnlineSubFields()

    // Specifique RDV-I
    document.addEventListener('turbolinks:load', this.toggleRdvInsertionFormChange());

    if (this.motifCategorySelect()) {
      this.motifCategorySelect().addEventListener('change', this.toggleRdvInsertionFormChange.bind(this));
    }
  }

}

export { MotifForm };
