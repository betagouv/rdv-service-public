# Sentry test helper setup, see:
# https://github.com/getsentry/sentry-ruby/blob/5.16.1/sentry-ruby/lib/sentry/test_helper.rb
def stub_sentry_events
  before do
    setup_sentry_test

    # Le middleware Rack `Sentry::Rack::CaptureExceptions` fait un appel à `clone_hub_to_current_thread`.
    # Cet appel a pour effet de remplacer le hub en place. On perd alors la référence des stubs utilisés
    # par le helper de test dans `setup_sentry_test`.
    # TODO: Créer une issue sur le repo de sentry-ruby
    allow(Sentry).to receive(:clone_hub_to_current_thread)
  end

  after do
    teardown_sentry_test
  end
end
