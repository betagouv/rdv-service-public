# rubocop:disable RSpec/AnyInstance, RSpec/StubbedMock
RSpec.describe CreateCrispTicketJob do
  describe "#perform" do
    let(:client) { instance_double(Crisp::Client) }
    let(:website) { instance_double(Crisp::WebsiteResource) }

    stub_env_with(CRISP_WEBSITE_ID: "abcde", CRISP_URN: "urn:crisp:1234567890")

    it "crée un ticket" do
      allow_any_instance_of(described_class).to receive(:client).and_return(client)
      allow(client).to receive(:website).and_return(website)
      expect(website).to receive(:create_new_conversation).with(ENV.fetch("CRISP_WEBSITE_ID")).and_return({ "session_id" => "12345" })
      expect(website).to receive(:send_message_in_conversation).with(
        ENV.fetch("CRISP_WEBSITE_ID"),
        "12345",
        {
          "type" => "text",
          "from" => "user",
          "origin" => ENV.fetch("CRISP_URN"),
          "content" => "message\n\n---\nMessage envoyé depuis le formulaire de contact\n",
        }
      )
      expect(website).to receive(:update_conversation_metas).with(
        ENV.fetch("CRISP_WEBSITE_ID"),
        "12345",
        {
          nickname: "nickname",
          email: "plop@unusager.fr",
          phone: "061234567",
          segments: %w[role domain],
          subject: "subject",
          device: {
            locales: ["fr"],
          },
        }
      )
      described_class.perform_now(email: "plop@unusager.fr", nickname: "nickname", phone: "061234567", subject: "subject", message: "message", role: "role", domain: "domain")
    end

    context "quand l’email n’a pas un format correct" do
      it "ne crée pas de ticket" do
        expect_any_instance_of(described_class).not_to receive(:client)
        described_class.perform_now(email: "invalid_email", nickname: "nickname", phone: "061234567", subject: "subject", message: "message", role: "role", domain: "domain")
      end
    end

    context "quand l’email est de type @example.com" do
      it "ne crée pas de ticket" do
        expect_any_instance_of(described_class).not_to receive(:client)
        described_class.perform_now(email: "toto@example.com", nickname: "nickname", phone: "061234567", subject: "subject", message: "message", role: "role", domain: "domain")
      end
    end
  end
end
# rubocop:enable RSpec/AnyInstance, RSpec/StubbedMock
