export default function setupCopyEmailButtons() {
  document.querySelectorAll('.js-copy-email').forEach(button => {
    const initialContent = button.textContent;

    button.addEventListener('click', e => {
      // Sur l'index, la cellule est dans un lien vers la page show et la ligne a un handler de clic
      e.preventDefault();
      e.stopPropagation();
      navigator.clipboard.writeText(button.dataset.clipboardContent).then(() => {
        button.textContent = '✅';
        setTimeout(() => {
          button.textContent = initialContent;
        }, 600);
      });
    });
  });
}
