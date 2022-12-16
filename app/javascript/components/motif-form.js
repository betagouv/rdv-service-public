// Used in admin/motifs/_form.html.slim:
// the checkboxes created by simpleform have the classes “motif_for_secretariat” and “motif_reservable_online”
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
    return !document.querySelector("#motif_follow_up:checked")
  }

  toggleSectorisation() {
    const enabled = this.reservableOnlineCheckbox.checked && this.sectorisationShouldBeDisable();
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
    const enabled = this.reservableOnlineCheckbox.checked
    document.querySelectorAll(".js-rdvs-editable").forEach(rdvEditableElement =>
      rdvEditableElement.classList.toggle('hidden', !enabled)
    )
  }

  toggleRdvsEditable() {
    const enabled = this.reservableOnlineCheckbox.checked
    document.querySelector("#motif_rdvs_editable_by_user").checked = enabled
  }

  constructor() {
    this.secretariatCheckbox = document.querySelector('#motif_for_secretariat')
    this.reservableOnlineCheckbox = document.querySelector('#motif_reservable_online')
    if (!this.secretariatCheckbox || !this.reservableOnlineCheckbox) return;

    const noSecretariatInputs = ["input[name=\"motif[location_type]\"]", "input[name=\"motif[follow_up]\"]"]
    document.querySelectorAll(noSecretariatInputs).forEach(input =>
      input.addEventListener('change', e => this.toggleSecretariat())
    )
    const noSectorisationInputs = ["input[name=\"motif[sectorisation_level]\"]", "input[name=\"motif[follow_up]\"]"]
    document.querySelectorAll(noSectorisationInputs).forEach(input =>
      input.addEventListener('change', e => this.toggleSectorisation())
    )
    this.reservableOnlineCheckbox.addEventListener('change', e => {
      if (document.querySelector(".js-sectorisation-card") !== null) { this.toggleSectorisation() }
      this.toggleOnlineSubFields()
      this.toggleRdvsEditable()
    })

    this.toggleSecretariat()
    if (document.querySelector(".js-sectorisation-card") !== null) { this.toggleSectorisation() }
    this.toggleOnlineSubFields()
  }

}

export { MotifForm };
