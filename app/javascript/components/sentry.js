import * as Sentry from '@sentry/browser';

function initSentry() {
  if (ENV.SENTRY_DSN_RAILS) {
    Sentry.init({
      dsn: ENV.SENTRY_DSN_RAILS,
      environment: ENV.SENTRY_CURRENT_ENV,
    });
    Sentry.setUser(ENV.SENTRY_USER_CONTEXT);
  }
}

$(document).on('turbolinks:load', function() {
  initSentry();
});

$(document).on('shown.bs.modal', '.modal', function(e) {
  initSentry();
});
