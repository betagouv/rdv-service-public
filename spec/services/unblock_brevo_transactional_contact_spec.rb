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
      stub = instance_double(Faraday::Response, status: 204)
      faraday_double = instance_double(Faraday::Request, headers: {}, options: Faraday::RequestOptions.new)
      expect(Faraday).to receive(:delete).with("https://api.brevo.com/v3/smtp/blockedContacts/#{CGI.escape(email)}")
        .and_yield(faraday_double)
        .and_return(stub)
      subject.call
    end

    it "notifie Sentry sans lever d'erreur si l'appel à Brevo échoue" do
      error = Faraday::TimeoutError.new("timeout")
      allow(Faraday).to receive(:delete).and_raise(error)
      expect(Sentry).to receive(:capture_exception).with(error, extra: { email: })
      expect { subject.call }.not_to raise_error
    end
  end
end
