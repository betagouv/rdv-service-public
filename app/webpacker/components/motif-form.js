class MotifForm {

  setSecretariatEnabled() {
    const enabled = this.secretariatShouldBeEnabled();
    if (enabled == this.secretariatEnabled) return;

    const secretariatCheckbox = document.querySelector('#motif_for_secretariat')
    if (!enabled) secretariatCheckbox.checked = false
    secretariatCheckbox.disabled = !enabled
    $(secretariatCheckbox).closest('.card').toggleClass('translucent', !enabled)

    this.secretariatEnabled = enabled
  }

  secretariatShouldBeEnabled() {
    return !document.querySelector("#motif_location_type_home:checked") &&
      !document.querySelector("#motif_follow_up:checked")
  }

  constructor() {

    if (!document.querySelector('#motif_for_secretariat')) return;

    const noSecretariatInputs = ["input[name=\"motif[location_type]\"]", "input[name=\"motif[follow_up]\"]"]
    document.querySelectorAll(noSecretariatInputs).forEach(input => {
      input.addEventListener('change', e => {
        this.setSecretariatEnabled()
      })
    })

    this.setSecretariatEnabled();
  }

}

export { MotifForm };
