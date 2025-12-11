document.addEventListener("DOMContentLoaded", function () {
  batchEditCheckboxes().forEach(e => e.addEventListener("change", refreshButtonState))

  const trigger = triggerCheckbox()
  if(trigger) {
    trigger.addEventListener("change", event => {
      batchEditCheckboxes().forEach(input => input.checked = trigger.checked)
      refreshButtonState()
    })
  }
});

function refreshButtonState() {
  const disabled = Array.from(batchEditCheckboxes()).filter(c => c.checked).length < 2;
  batchEditButton().disabled = disabled;
  batchEditButton().classList.toggle("btn-outline-primary", !disabled)
}

function batchEditCheckboxes() {
  return document.querySelectorAll(".js-batch-edit-checkbox")
}

function batchEditButton() {
  return document.querySelector(".js-batch-edit-button")
}

function triggerCheckbox() {
  return document.querySelector(".js-trigger-checkbox")
}
