import { initSelect2 } from "components/select2"

class AgentUserForm {
  constructor() {
    this.formElt = document.querySelector(".js-agent-user-form")
    if (!this.formElt) return

    const checkedTypeRadio = this.formElt.querySelector(".js-responsability-type:checked")
    this.currentResponsabilityType = checkedTypeRadio ? checkedTypeRadio.value : null
    this.currentRelativeType = this.formElt.querySelector(".js-relative-tab-link.active").dataset.relativeType

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
    this.formElt.querySelectorAll("input[type=email]").forEach(elt => {
      elt.addEventListener("change", this.onEmailChangeHandler);
      elt.dispatchEvent(new Event("change"));
    })
  }

  onEmailChangeHandler = (evt) =>
    evt.currentTarget.
      parentElement.parentElement.
      querySelector(".js-invite-row").
      classList.toggle("d-none", !evt.currentTarget.value)

  refreshVisibleFields = () => {
    this.formElt.querySelectorAll("div[data-togglable]").forEach(d =>
      d.classList.toggle("d-none", !this.divShouldBeVisible(d))
    )
    this.formElt.querySelectorAll("input[data-togglable], select[data-togglable]").forEach(i =>
      i.disabled = !this.inputShouldBeEnabled(i)
    )
    initSelect2()
  }

  divShouldBeVisible = (divElt) => {
    return divElt.dataset.responsabilityType == this.currentResponsabilityType
  }

  inputShouldBeEnabled = (inputElt) => {
    const { responsabilityType, relativeType } = inputElt.dataset
    return (
      responsabilityType == this.currentResponsabilityType &&
      (!relativeType || relativeType == this.currentRelativeType)
    )
  }
}

export { AgentUserForm }
