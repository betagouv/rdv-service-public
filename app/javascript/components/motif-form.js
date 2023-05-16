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
    const enabled = !this.bookableByAgentsButton.checked
    document.querySelectorAll(".js-rdvs-editable").forEach(rdvEditableElement =>
      rdvEditableElement.classList.toggle('hidden', !enabled)
    )
  }

  toggleRdvsEditable() {
    const enabled = !this.bookableByAgentsButton.checked
    document.querySelector("#motif_rdvs_editable_by_user").checked = enabled
  }

  toggleRdvInsertionNotifsDivs = () => {
    // Specifique RDV-I temporaire
    const selectedValue = this.motifCategorySelect?.value;
    const hiddenDivs = document.getElementsByClassName('rdv-insertion-notif-hint');

    Array.from(hiddenDivs).forEach(div => {
      div.style.display = (selectedValue != "" && selectedValue != undefined) ? 'block' : 'none';
    });
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

    // Specifique RDV-I temporaire
    document.addEventListener('turbolinks:load', this.toggleRdvInsertionNotifsDivs);

    this.motifCategorySelect = document.getElementById('motif_motif_category_id')
    if (this.motifCategorySelect) {
      this.motifCategorySelect.addEventListener('change', this.toggleRdvInsertionNotifsDivs)
    }
  }

}

export { MotifForm };
