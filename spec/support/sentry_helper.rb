# Sentry test helper setup, see:
# https://github.com/getsentry/sentry-ruby/blob/5fc11d9/sentry-ruby/lib/sentry/test_helper.rb
def stub_sentry_events
  before do
    setup_sentry_test
  end

  after do
    teardown_sentry_test
  end
end
