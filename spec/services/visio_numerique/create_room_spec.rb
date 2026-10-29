RSpec.describe VisioNumerique::CreateRoom do
  let(:rooms_api_url) { "#{described_class::DEFAULT_API_URL}/rooms/" }
  let(:agent) { build(:agent) }

  before do
    stub_request(:post, rooms_api_url)
      .to_return(status: 200, body: { url: "https://visio.numerique.gouv.fr/salon" }.to_json, headers: { "Content-Type" => "application/json" })
  end

  describe "#visio_url" do
    context "quand l'agent a un jeton Menshen valide" do
      let(:agent) { build(:agent, menshen_access_token: "jeton-menshen", menshen_access_token_expires_at: 1.hour.from_now) }

      it "crée le salon avec le jeton Menshen, même si un access token ProConnect est fourni" do
        expect(described_class.new(agent:, pro_connect_access_token: "jeton-proconnect").visio_url).to eq("https://visio.numerique.gouv.fr/salon")

        expect(WebMock).to have_requested(:post, rooms_api_url).with(headers: { "Authorization" => "Bearer jeton-menshen" })
      end

      it "crée le salon sans access token ProConnect" do
        expect(described_class.new(agent:).visio_url).to eq("https://visio.numerique.gouv.fr/salon")

        expect(WebMock).to have_requested(:post, rooms_api_url).with(headers: { "Authorization" => "Bearer jeton-menshen" })
      end
    end

    context "quand le jeton Menshen de l'agent a expiré" do
      let(:agent) { build(:agent, menshen_access_token: "jeton-menshen", menshen_access_token_expires_at: 1.minute.ago) }

      it "crée le salon avec l'access token ProConnect" do
        described_class.new(agent:, pro_connect_access_token: "jeton-proconnect").visio_url

        expect(WebMock).to have_requested(:post, rooms_api_url).with(headers: { "Authorization" => "Bearer jeton-proconnect" })
      end
    end

    context "quand l'agent n'a pas de jeton Menshen" do
      it "crée le salon avec l'access token ProConnect" do
        described_class.new(agent:, pro_connect_access_token: "jeton-proconnect").visio_url

        expect(WebMock).to have_requested(:post, rooms_api_url).with(headers: { "Authorization" => "Bearer jeton-proconnect" })
      end

      it "ne crée pas de salon sans access token ProConnect" do
        expect(described_class.new(agent:).visio_url).to be_nil

        expect(WebMock).not_to have_requested(:post, rooms_api_url)
      end
    end
  end
end
