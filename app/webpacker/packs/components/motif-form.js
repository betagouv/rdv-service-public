class MotifForm {

  setSecretariatEnabled(enabled) {
    // short circuit if no change
    if (enabled == this.secretariatEnabled) return;

    const secretariatCheckbox = document.
      querySelector('input[type=checkbox][name=\"motif[for_secretariat]\"]')
    if (!enabled) secretariatCheckbox.checked = false // uncheck before disabling
    secretariatCheckbox.disabled = !enabled
    secretariatCheckbox.closest('.card').classList.toggle('translucent', !enabled)

    this.secretariatEnabled = enabled
  }

  constructor() {
    // short circuit when not on the motif form page
    const inputs = document.querySelectorAll("input[name=\"motif[location_type]\"")
    if (!inputs) return false;

    // initial boolean value is true as the html displays the input enabled in
    // all cases
    this.secretariatEnabled = true

    // initial toggle depends on whether the 'home' radio is checked
    const initialValue = !document.querySelector("#motif_location_type_home:checked");
    this.setSecretariatEnabled(initialValue)

    // attach listeners to all radio buttons. the change event is triggered only
    // on the one that's being selected
    inputs.forEach(input => {
      input.addEventListener('change', e => {
        this.setSecretariatEnabled(e.currentTarget.value != 'home')
      })
    })
  }
}

export { MotifForm };
