export default function DsfrNewPassword() {
  const component = document.querySelector(`[data-component="js_dsfr_new_password"]`)
  if(!component) { return }

  const input = component.querySelector(`input[type="password"]`)
  const minLengthMessage = component.querySelector(`[data-component="js_dsfr_new_password__min_length_message"]`)

  const atLeastOneDigitMessage = component.querySelector(`[data-component="js_dsfr_new_password__at_least_one_digit_message"]`)

  const minLength = parseInt(minLengthMessage.dataset.minLength)

  input.addEventListener('input', event=> {
    if(input.value.length >= minLength) {
      minLengthMessage.classList.remove("fr-message--info")
      minLengthMessage.classList.add("fr-message--valid")
    } else {
      minLengthMessage.classList.add("fr-message--info")
      minLengthMessage.classList.remove("fr-message--valid")
    }

    if(input.value.match(/\d/g)) {
      atLeastOneDigitMessage.classList.remove("fr-message--info")
      atLeastOneDigitMessage.classList.add("fr-message--valid")
    } else {
      atLeastOneDigitMessage.classList.add("fr-message--info")
      atLeastOneDigitMessage.classList.remove("fr-message--valid")
    }
  })
}
