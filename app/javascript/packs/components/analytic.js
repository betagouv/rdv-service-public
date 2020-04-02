class Analytic {

  constructor() {
    var _paq = window._paq || [];
    _paq.push(['trackPageView']);
    _paq.push(['enableLinkTracking']);
    (function() {
      var u="//stats.data.gouv.fr/";
      _paq.push(['setTrackerUrl', u+'piwik.php']);
      _paq.push(['setSiteId', ENV.MATOMO_APP_ID]);
      var d=document, g=d.createElement('script'), s=d.getElementsByTagName('script')[0];
      g.type='text/javascript'; g.async=true; g.defer=true; g.src=u+'piwik.js'; s.parentNode.insertBefore(g,s);
    })();
  }

  trackPageView(partialUrl) {
    if (window._paq) {
      _paq.push(['setDocumentTitle', location.href.split('#')[0]);
      if (partialUrl) {
        _paq.push(['setDocumentTitle', partialUrl);
      }
      _paq.push(['trackPageView']);
    }
  }

  trackEvent(type, value) {
    if (window._paq) {
      _paq.push(['setDocumentTitle', location.href.split('#')[0]);
      _paq.push(['trackPageView']);
    }
  }

  trackEventWithLabel(category, action, label) {
    if (window._paq) {
      _paq.push(['setDocumentTitle', location.href.split('#')[0]);
      _paq.push(['trackPageView']);
    }
  }

  trackModalView(evt) {
    this.trackPageView($(evt.currentTarget).data("url"))
  }

  trackRightbarView(evt) {
    this.trackPageView($(evt.currentTarget).data("url"))
  }

}

export { Analytic };
