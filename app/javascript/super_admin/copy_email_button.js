export default () => {
  document.querySelectorAll('.js-copy-email').forEach(button => {
    button.addEventListener('click', e => {
      // Sur l'index, la cellule est dans un lien vers la page show et la ligne a un handler de clic
      e.preventDefault()
      e.stopPropagation()
      navigator.clipboard.writeText(button.dataset.clipboardContent)
      button.textContent = '✅'
    })
  })
}
