// voir Agent#password_complexity
export default function DsfrNewPassword() {
  const component = document.querySelector(`[data-component="js_dsfr_new_password"]`)
  if(!component) { return }

  const input = component.querySelector(`input[type="password"]`)
  const minLengthMessage = component.querySelector(`[data-component="js_dsfr_new_password__min_length_message"]`)

  const atLeastOneDigitMessage = component.querySelector(`[data-component="js_dsfr_new_password__at_least_one_digit_message"]`)

  const atLeastOneCapitalLetterMessage = component.querySelector(`[data-component="js_dsfr_new_password__at_least_one_capital_letter_message"]`)

  const atLeastOneSpecialCharacterMessage = component.querySelector(`[data-component="js_dsfr_new_password__at_least_one_special_character_message"]`)

  const minLength = parseInt(minLengthMessage.dataset.minLength)

  input.addEventListener('input', event=> {
    if(input.value.length >= minLength) {
      minLengthMessage.classList.remove("fr-message--info")
      minLengthMessage.classList.add("fr-message--valid")
    } else {
      minLengthMessage.classList.remove("fr-message--valid")
      minLengthMessage.classList.add("fr-message--info")
    }

    if(input.value.match(/\d/g)) {
      atLeastOneDigitMessage.classList.remove("fr-message--info")
      atLeastOneDigitMessage.classList.add("fr-message--valid")
    } else {
      atLeastOneDigitMessage.classList.remove("fr-message--valid")
      atLeastOneDigitMessage.classList.add("fr-message--info")
    }

    if(input.value !== input.value.toLowerCase()) {
      atLeastOneCapitalLetterMessage.classList.remove("fr-message--info")
      atLeastOneCapitalLetterMessage.classList.add("fr-message--valid")
    } else {
      atLeastOneCapitalLetterMessage.classList.remove("fr-message--valid")
      atLeastOneCapitalLetterMessage.classList.add("fr-message--info")
    }

    if(input.value.match(/[^A-Za-z0-9_]/g)) {
      atLeastOneSpecialCharacterMessage.classList.remove("fr-message--info")
      atLeastOneSpecialCharacterMessage.classList.add("fr-message--valid")
    } else {
      atLeastOneSpecialCharacterMessage.classList.remove("fr-message--valid")
      atLeastOneSpecialCharacterMessage.classList.add("fr-message--info")
    }
  })
}
