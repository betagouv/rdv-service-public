class CheckAll {
  constructor() {
    document.querySelectorAll(".js-check-all").forEach(button => {
      button.addEventListener("click", event => {
        event.preventDefault()
        const inputsToCheck = document.querySelectorAll(event.target.dataset.checkAllMatching)
        inputsToCheck.forEach(input => input.checked = true)
      })
    })
  }
}

class UnCheckAll {
  constructor() {
    document.querySelectorAll(".js-uncheck-all").forEach(button => {
      button.addEventListener("click", event => {
        event.preventDefault()
        const inputsToUncheck = document.querySelectorAll(event.target.dataset.uncheckAllMatching)
        inputsToUncheck.forEach(input => input.checked = false)
      })
    })
  }
}

export { CheckAll, UnCheckAll }
