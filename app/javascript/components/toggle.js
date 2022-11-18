document.addEventListener("click", function(event) {
  const trigger = event.target;
  if(!trigger.classList.contains("js-toggle")) {
    return;
  }

  const targetSelector = trigger.dataset.toggleTarget;

  if(targetSelector) {
    const targetElement = document.querySelector(targetSelector);

    if(targetElement) {
      targetElement.classList.toggle("hidden");
    }
  }
});
