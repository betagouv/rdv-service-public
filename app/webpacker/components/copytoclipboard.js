

function initCopyToClipBoard() {
  $(function () {
    document.querySelectorAll(".js-copy-to-clipboard").forEach(element => {
      element.addEventListener("click", event => {
        console.log(event)
        event.preventDefault()
        navigator.clipboard.writeText(event.target.dataset.tocopy)
      }, {capture : true})
    })
  })
}

$(document).on('turbolinks:load', function() {
  initCopyToClipBoard();
});

