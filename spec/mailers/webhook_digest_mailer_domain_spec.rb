RSpec.describe WebhookDigestMailer do
  subject(:sent_email) { described_class.weekly_digest(notification_email:, first_day:) }

  let(:notification_email) { "i-love-webhooks@conseil-general.fr" }
  let(:first_day) { Date.new(2025, 1, 27) } # un lundi

  it "gives the global success rate" do
    expect(sent_email.html_part.body.to_s).to include("50 % d'envois en échec")
  end
end
