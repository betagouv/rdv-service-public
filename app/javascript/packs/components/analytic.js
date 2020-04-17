let previousPageUrl = null;

const paramsToFilter = ['address', 'first_name', 'last_name', 'affiliation_number', 'latitude', 'longitude', 'where', 'invitation_token', 'confirmation_token', 'unlock_token', 'reset_password_token', 'search[departement]', 'search[latitude]', 'search[longitude]', 'search[where]'];

if (ENV.ENV == "production") {
  window._paq = window._paq || [];

  const url = '//stats.data.gouv.fr/';
  const trackerUrl = `${url}piwik.php`;
  const jsUrl = `${url}piwik.js`;

  // Configure Matomo analytics
  //window._paq.push(['setCookieDomain', '*.www.demarches-simplifiees.fr']);
  //window._paq.push(['setDomains', ['*.www.demarches-simplifiees.fr']]);
  window._paq.push(['setDoNotTrack', true]);
  window._paq.push(['setCustomUrl', customHref()]);
  window._paq.push(['trackPageView']);
  window._paq.push(['enableLinkTracking']);

  // Load script from Matomo
  window._paq.push(['setTrackerUrl', trackerUrl]);
  window._paq.push(['setSiteId', ENV.MATOMO_APP_ID]);

  const script = document.createElement('script');
  const firstScript = document.getElementsByTagName('script')[0];
  script.type = 'text/javascript';
  script.id = 'matomo-js';
  script.async = true;
  script.src = jsUrl;
  firstScript.parentNode.insertBefore(script, firstScript);

  addEventListener('turbolinks:load', sendDataToMatomo);
  $(document).on('shown.rightbar', '.right-bar', sendDataToMatomo);
  $(document).on('shown.bs.modal', '.modal', sendDataToMatomo);
}

function sendDataToMatomo (event) {

  // Send Matomo a new event when navigating to a new page using Turbolinks
  // (see https://developer.matomo.org/guides/spa-tracking)
  if (previousPageUrl) {
    window._paq.push(['setReferrerUrl', previousPageUrl]);
    window._paq.push(['setCustomUrl', customHref()]);
    window._paq.push(['setDocumentTitle', document.title]);
    if (event.data && event.data.timing) {
      window._paq.push([
        'setGenerationTimeMs',
        event.data.timing.visitEnd - event.data.timing.visitStart
      ]);
    }
    window._paq.push(['trackPageView']);
  }
  previousPageUrl = customHref;
}


function customHref () {
  let customHref = window.location.href;

  paramsToFilter.forEach(function(paramToFilter) {
    let expression = new RegExp(`${paramToFilter}=([^&]+)&?`);
    customHref = customHref.replace(expression, '');
  });

  return customHref;
}
