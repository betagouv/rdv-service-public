export default function PreventDefault() {
  document.querySelectorAll(".js-prevent-default-onclick").forEach(button => {
    button.addEventListener("click", evt => {
      evt.preventDefault();
    })
  });
}
