document.addEventListener("turbolinks:load", function () {
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
  batchEditButton().disabled = Array.from(batchEditCheckboxes()).filter(c => c.checked).length < 2;
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
