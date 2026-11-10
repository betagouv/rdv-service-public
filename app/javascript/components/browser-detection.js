import Bowser from "bowser";
const browser = Bowser.getParser(window.navigator.userAgent);

document.addEventListener("DOMContentLoaded", function() {
  // ces versions sont celles déclarées pour la config "target" dans esbuild.config.mjs.
  const oldBrowser = browser.satisfies({
    chrome: "<90",
    firefox: "<90",
    edge: "<90",
    safari: "<15",
  });

  if (oldBrowser){
    let html = "<div id='browser-upgrade' class='text-center bg-warning py-1'><b>Vous semblez utiliser un navigateur obsolète incompatible avec cette plateforme.</b> <a href='https://browsehappy.com/' target='_blank'>Télécharger un navigateur récent</a></div>"
    if ($('#browser-upgrade').length == 0){
      $('body').prepend(html)
    }
  }
})
