import { initSelect2 } from "components/select2"
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
    this.formElt.querySelectorAll("input[type=email]").forEach(elt => {
      elt.addEventListener("change", this.onEmailChangeHandler);
      elt.dispatchEvent(new CustomEvent("change"));
    })
  }

  onEmailChangeHandler = (evt) => {
    const inviteRow = evt.currentTarget.parentElement.parentElement.querySelector(".js-invite-row");
    if (!inviteRow) return
    inviteRow.classList.toggle("d-none", !evt.currentTarget.value)
  }

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
