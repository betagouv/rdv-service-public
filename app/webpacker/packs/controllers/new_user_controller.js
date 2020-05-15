import { Controller } from "stimulus"

export default class extends Controller {

  static targets = [ "typeRadio", "form" ]

  connect() {
    let checkedTypeRadio = this.typeRadioTargets.find(el => el.checked);
    if (!checkedTypeRadio) {
      checkedTypeRadio = this.typeRadioTargets.find(el => el.value == "responsible");
      checkedTypeRadio.checked = 'checked';
    }
    this.userType = checkedTypeRadio ? checkedTypeRadio.value : null;
    this.attachUserTypeListeners()
    this.refreshVisibleForms()
  }

  attachUserTypeListeners = () => {
    this.typeRadioTargets.forEach(elt => {
      elt.addEventListener("change", evt => {
        this.userType = evt.currentTarget.value;
        this.refreshVisibleForms()
      })
    })
  }

  refreshVisibleForms = () => {
    this.formTargets.forEach(elt => {
      elt.classList.toggle("d-none", elt.getAttribute("data-user-type") != this.userType)
    })
  }
}
