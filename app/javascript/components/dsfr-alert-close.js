export default function DsfrAlertClose() {
  document.querySelectorAll(".fr-btn--close").forEach(closeButton => {
    closeButton.addEventListener("click", event => {
      const alert = event.target.parentNode;
      alert.parentNode.removeChild(alert);
    });
  });
}
