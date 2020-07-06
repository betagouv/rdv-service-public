import { Controller } from "stimulus"
import { initSelect2 } from "components/select2"

export default class extends Controller {
  static targets = [ "form", "typeRadio", "toggleDiv", "toggleInput", "pills" ]

  connect() {
    if (this.formTarget.classList.contains("edit_user")) return;

    let checkedTypeRadio = this.typeRadioTargets.find(el => el.checked);
    this.currentResponsabilityType = checkedTypeRadio ? checkedTypeRadio.value : null;
    this.currentRelativeType = this.hasPillsTarget && this.pillsTarget.querySelector("a.active").dataset.relativeType
    this.attachListeners()
    this.refreshVisibleFields()
  }

  attachListeners = () => {
    this.typeRadioTargets.forEach(elt => {
      elt.addEventListener("change", evt => {
        this.currentResponsabilityType = evt.currentTarget.value;
        this.refreshVisibleFields()
      })
    })
    // cannot use target on `a` directly because of bootstrap-stimulus conflict
    // https://github.com/stimulusjs/stimulus/issues/226
    this.hasPillsTarget && this.pillsTarget.querySelectorAll("a").forEach(elt =>
      $(elt).on("shown.bs.tab", () => {
        this.currentRelativeType = elt.dataset.relativeType
        this.refreshVisibleFields()
      })
    )
  }

  refreshVisibleFields = () => {
    this.toggleDivTargets.forEach(elt => {
      elt.classList.toggle(
        "d-none",
        elt.dataset.responsabilityType != this.currentResponsabilityType
      )
    })
    this.toggleInputTargets.forEach(inputElt =>
      inputElt.disabled = !(
        inputElt.dataset.responsabilityType == this.currentResponsabilityType && (
          !inputElt.dataset.relativeType ||
          inputElt.dataset.relativeType == this.currentRelativeType
        )
      )
    )
    initSelect2()
  }
}
