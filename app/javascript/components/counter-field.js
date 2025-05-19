export default function CounterField() {
  document
    .querySelectorAll('[data-controller="counter-field"]')
    .forEach(controllerElt => {
      const inputElt = controllerElt.querySelector(`[data-counter-field-target="input"]`)
      const decrementElts = controllerElt.querySelectorAll('[data-action="click->counter-field#decrement"]')
      const incrementElts = controllerElt.querySelectorAll('[data-action="click->counter-field#increment"]')

      if (!inputElt) return

      const maxValue = inputElt.dataset.max || 1000
      const minValue = inputElt.dataset.min || 0

      const updateDisabled = () => {
        decrementElts.forEach((elt) => {
          elt.disabled = parseInt(inputElt.value) <= minValue
        })

        incrementElts.forEach((elt) => {
          elt.disabled = parseInt(inputElt.value) >= maxValue
        })
      }
      updateDisabled()

      decrementElts.forEach((elt) => {
        elt.addEventListener('click', (event) => {
          event.preventDefault()
          if (parseInt(inputElt.value) > minValue)
            inputElt.value = parseInt(inputElt.value) - 1
          updateDisabled()
        })
      })

      incrementElts.forEach((elt) => {
        elt.addEventListener('click', (event) => {
          event.preventDefault()
          if (parseInt(inputElt.value) < maxValue)
            inputElt.value = parseInt(inputElt.value) + 1
          updateDisabled()
        })
      })

      inputElt.addEventListener("change", (event) => {
        event.preventDefault()
        updateDisabled()
      })
  })
}
