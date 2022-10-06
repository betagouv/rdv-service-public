# frozen_string_literal: true

# Sentry test helper setup, see:
# https://github.com/getsentry/sentry-ruby/blob/5fc11d9/sentry-ruby/lib/sentry/test_helper.rb
def stub_sentry_events
  around do |example|
    setup_sentry_test
    example.run
    teardown_sentry_test
  end
end
