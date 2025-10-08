export default () => {
  document.querySelectorAll('.js-copy-to-clipboard').forEach(button => {

    button.addEventListener('click', e => {
      navigator.clipboard.writeText(button.dataset.clipboardContent)
      button.innerHTML = "copié"
    })

  })
}
