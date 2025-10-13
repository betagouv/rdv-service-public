export default () => {
  document.querySelectorAll('.js-copy-to-clipboard').forEach(button => {

    button.addEventListener('click', e => {
      navigator.clipboard.writeText(button.dataset.clipboardContent)
      button.innerHTML = '<span class="fr-icon-check-line fr-icon--sm fr-mr-1v" aria-hidden="true"></span> copié'
    })

  })
}
