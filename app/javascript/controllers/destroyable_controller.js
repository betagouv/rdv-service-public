import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="destroyable"
export default class extends Controller {
  static targets = [
    "destroyInput"
  ]

  destroyItem = (event) => {
    const userId = this.destroyInputTarget.closest("[data-controller=destroyable]").querySelector("input[name*=user_id]")?.value
    event.preventDefault();
    this.element.classList.add("d-none");
    this.destroyInputTarget.value = true;

    if (userId) {
      let url = new URL(window.location.href);
      // user_ids est supporté par Admin::RdvsCollectifsController mais peut-être déprécié
      for (const paramName of ["add_user[]", "user_ids[]"]) {
        const userIds = url.searchParams.getAll(paramName)
        if (userIds.includes(userId)) {
          url.searchParams.delete(paramName, userId)
          window.location.href = url
          return
        }
      }
    }

  }
}


