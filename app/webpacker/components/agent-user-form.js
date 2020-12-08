import { Select2Inputs } from "components/select2-inputs"
import 'custom-event-polyfill'

class AgentUserForm {
  constructor() {
    this.formElt = document.querySelector(".js-agent-user-form")
    if (!this.formElt) return

    const checkedTypeRadio = this.formElt.querySelector(".js-responsability-type:checked")
    this.currentResponsabilityType = checkedTypeRadio ? checkedTypeRadio.value : null
    const currentRelativeTabElt = this.formElt.querySelector(".js-relative-tab-link.active")
    this.currentRelativeType = currentRelativeTabElt && currentRelativeTabElt.dataset.relativeType

    this.attachListeners()
    this.refreshVisibleFields()
  }

  attachListeners = () => {
    this.formElt.querySelectorAll('.js-responsability-type').forEach(elt =>
      elt.addEventListener("change", evt => {
        this.currentResponsabilityType = evt.currentTarget.value
        this.refreshVisibleFields()
      })
    )
    this.formElt.querySelectorAll(".js-relative-tab-link").forEach(elt =>
      $(elt).on("shown.bs.tab", () => {
        this.currentRelativeType = elt.dataset.relativeType
        this.refreshVisibleFields()
      })
    )
  }

  refreshVisibleFields = () => {
    this.formElt.querySelectorAll("div[data-togglable]").forEach(d =>
      d.classList.toggle("d-none", !this.divShouldBeVisible(d))
    )
    this.formElt.querySelectorAll("input[data-togglable], select[data-togglable], textarea[data-togglable]").forEach(inputElt => {
      const newDisabledValue = !this.inputShouldBeEnabled(inputElt)
      inputElt.disabled = newDisabledValue
      // bind disabled attribute of checkboxes' hidden field with 0 value
      if (
        inputElt.previousSibling &&
        inputElt.previousSibling.type == "hidden" &&
        inputElt.previousSibling.tagName == inputElt.tagName &&
        inputElt.previousSibling.name == inputElt.name
      )
        inputElt.previousSibling.disabled = newDisabledValue
    })
    new Select2Inputs()
  }

  divShouldBeVisible = (divElt) => {
    return divElt.dataset.responsabilityType == this.currentResponsabilityType
  }

  inputShouldBeEnabled = (inputElt) => {
    if (inputElt.classList.contains("js-force-disabled"))
      return false
    const { responsabilityType, relativeType } = inputElt.dataset
    return (
      responsabilityType == this.currentResponsabilityType &&
      (!relativeType || relativeType == this.currentRelativeType)
    )
  }
}

export { AgentUserForm }
