class Analytic {

  constructor() {
    (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
    (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
    m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
    })(window,document,'script','//www.google-analytics.com/analytics.js','ga');
    ga('create', ENV.GOOGLE_ANALYTICS, 'auto');
  }

  trackPageView(partialUrl) {
    if (window.ga) {
      ga('set', 'location', location.href.split('#')[0]);
      if (partialUrl) {
        ga('send', 'pageview', partialUrl)
      }
      else {
        ga('send', 'pageview')
      }
    }
  }

  trackEvent(type, value) {
    if (window.ga) {
      ga('set', 'location', location.href.split('#')[0]);
      ga('send', 'event', type, value);
    }
  }

  trackEventWithLabel(category, action, label) {
    if (window.ga) {
      ga('set', 'location', location.href.split('#')[0]);
      ga('send', 'event', category, action, label)
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
