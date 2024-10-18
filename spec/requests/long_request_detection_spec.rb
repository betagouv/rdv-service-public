RSpec.describe "detecting long-running requests" do
  it "works" do
    stub_const "LongRequestNotifyMiddleware::TIME_LIMIT", 0.00001.seconds
    get "/health_check"
    expect(sentry_events.last.message).to start_with("Long request detected: /health_check took")
  end
end
