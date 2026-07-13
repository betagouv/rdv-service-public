RSpec.describe UnblockBrevoTransactionalContact, type: :service do
  subject { described_class.new(email) }

  let(:email) { "test@example.com" }

  context "quand la clé n'est pas set" do
    stub_env_with(BREVO_API_KEY: nil)

    it "n'envoie rien si on n'est pas en production" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
      expect(Sentry).not_to receive(:capture_message)
      subject.call
    end

    it "envoie un Sentry si on est en production" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
      expect(Sentry).to receive(:capture_message).with(
        "BREVO_API_KEY is not set, cannot unblock Brevo transactional contact",
        level: :error
      )
      subject.call
    end
  end

  context "quand la clé est set" do
    stub_env_with(BREVO_API_KEY: "fake-key")

    it "fait l'appel Faraday" do
      stub_request(:delete, "https://api.brevo.com/v3/smtp/blockedContacts/test%40example.com")
      subject.call
      expect(WebMock).to have_requested(:delete, "https://api.brevo.com/v3/smtp/blockedContacts/test%40example.com").with(headers: { "Api-Key" => "fake-key", "Accept" => "application/json" })
    end

    it "loggue l'appel à Sentry en cas d'échec" do
      stub_request(:delete, "https://api.brevo.com/v3/smtp/blockedContacts/#{CGI.escape(email)}").and_return({ status: 500, body: { error: "something happened and i'm sorry" }.to_json })
      expect { subject.call }.to raise_error(Faraday::ServerError)

      Sentry.capture_message("woops")
      request_breadcrumb, response_breadcrumb = sentry_events.last.breadcrumbs.compact
      expect(request_breadcrumb.data[:url].to_s).to eq("https://api.brevo.com/v3/smtp/blockedContacts/test%40example.com")
      expect(response_breadcrumb.data[:body]).to eq({ error: "something happened and i'm sorry" }.to_json)
    end
  end
end
