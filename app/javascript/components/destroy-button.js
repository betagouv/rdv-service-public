// Component: generic destroy button for a Rails form
// See also _destroy_button.html.slim

class DestroyButton {
  constructor() {
    this.$button = $(".js-destroy-button")
    if (!this.$button) return

    this.$button.on("click", this.destroyItem)
  }

  destroyItem = (event) => {
    event.preventDefault();
    let id = event.target.closest(".js-destroy-button").dataset.target;
    document.getElementById(id).style.display = 'none';
    document.getElementById(id+"-destroy").value = true
  }
}

export { DestroyButton }
