class Analytic {

  constructor() {
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