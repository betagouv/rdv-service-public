import Bowser from "bowser";
const browser = Bowser.getParser(window.navigator.userAgent);

document.addEventListener('turbolinks:load', function() {
  const oldBrowser = browser.satisfies({
    chrome: "<29",
    firefox: "<28",
    opera: "<15",
    edge: "<12",
    ie: '<11'
  });

  if (isInvalidValidBrowser){
    let html = "<div id='browser-upgrade' class='text-center bg-warning py-1'><b>Votre navigateur n'est pas optimal pour utiliser Lapins.</b> <a href='http://browsehappy.com/' target='_blank'>Télécharger un navigateur récent</a>  (Chrome, Firefox, Safari, InternetExplorer 11) </div>"
  if (oldBrowser){
    let html = "<div id='browser-upgrade' class='text-center bg-warning py-1'><b>Votre navigateur n'est pas optimal pour utiliser Lapins.</b> <a href='http://browsehappy.com/' target='_blank'>Télécharger un navigateur récent</a>  (Chrome, Firefox, Safari, Internet Explorer 11) </div>"
    if ($('#browser-upgrade').length == 0){
      $('body').prepend(html)
    }
  }
})
