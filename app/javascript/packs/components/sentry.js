import * as Sentry from '@sentry/browser';

function initSentry() {
  if (ENV.SENTRY_DSN_RAILS) {
    // https://blog.sentry.io/2017/03/27/tips-for-reducing-javascript-error-noise
    Raven.config(ENV.SENTRY_DSN_RAILS, {
      whitelistUrls: [
        'rdv-solidarites.fr',
        'http://lapin-beta-gouv.herokuapp.com',
        'ajax.googleapis.com'
      ]
    }).install();
    Sentry.init({
      dsn: ENV.SENTRY_DSN_RAILS,
      environment: ENV.ENV,
    });
  }
}

$(document).on('turbolinks:load', function() {
  initSentry();
});

$(document).on('shown.rightbar', '.right-bar', function(e) {
  initSentry();
});

$(document).on('shown.bs.modal', '.modal', function(e) {
  initSentry();
});
