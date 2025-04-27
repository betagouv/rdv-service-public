export default function CounterField() {
  const inputElt = document.querySelector(`[data-counter-field-target="input"]`)

  if (!inputElt) return

  const maxValue = inputElt.dataset.max || 1000
  const minValue = inputElt.dataset.min || 0

  const updateDisabled = () => {
    document.querySelectorAll('[data-action="click->counter-field#decrement"]').forEach((elt) => {
      elt.disabled = parseInt(inputElt.value) <= minValue
    })

    document.querySelectorAll('[data-action="click->counter-field#increment"]').forEach((elt) => {
      elt.disabled = parseInt(inputElt.value) >= maxValue
    })
  }
  updateDisabled()

  document.querySelectorAll('[data-action="click->counter-field#decrement"]').forEach((elt) => {
    elt.addEventListener('click', (event) => {
      event.preventDefault()
      if (parseInt(inputElt.value) > minValue) {
        inputElt.value = parseInt(inputElt.value) - 1
      updateDisabled()
      }
    })
  })

  document.querySelectorAll('[data-action="click->counter-field#increment"]').forEach((elt) => {
    elt.addEventListener('click', (event) => {
      event.preventDefault()
      if (parseInt(inputElt.value) < maxValue)
        inputElt.value = parseInt(inputElt.value) + 1
      updateDisabled()
    })
  })
}
