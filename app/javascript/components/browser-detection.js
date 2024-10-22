import Bowser from "bowser";
const browser = Bowser.getParser(window.navigator.userAgent);

document.addEventListener("DOMContentLoaded", function() {
  const oldBrowser = browser.satisfies({
    chrome: "<78",
    firefox: "<68",
    edge: "<17",
  });

  if (oldBrowser){
    let html = "<div id='browser-upgrade' class='text-center bg-warning py-1'><b>Votre navigateur n'est pas optimal pour utiliser RDV Solidarités.</b> <a href='http://browsehappy.com/' target='_blank'>Télécharger un navigateur récent</a>  (Chrome, Firefox, Edge) </div>"
    if ($('#browser-upgrade').length == 0){
      $('body').prepend(html)
    }
  }
})
