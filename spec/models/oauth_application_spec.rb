RSpec.describe OauthApplication do
  describe "validations" do
    context "avec le grant_type authorization_code (défaut)" do
      it "est valide avec un redirect_uri" do
        application = build(:oauth_application, redirect_uri: "https://example.com/callback")
        expect(application).to be_valid
      end

      it "est invalide sans redirect_uri" do
        application = build(:oauth_application, redirect_uri: nil)
        expect(application).not_to be_valid
        expect(application.errors[:redirect_uri]).to be_present
      end

      it "n'exige pas d'agent associé" do
        application = build(:oauth_application, agent: nil)
        expect(application).to be_valid
      end
    end

    context "avec le grant_type client_credentials" do
      it "est valide avec un agent associé et sans redirect_uri" do
        application = build(:oauth_application, grant_type: "client_credentials", agent: build(:agent), redirect_uri: nil)
        expect(application).to be_valid
      end

      it "est invalide sans agent associé" do
        application = build(:oauth_application, grant_type: "client_credentials", agent: nil, redirect_uri: nil)
        expect(application).not_to be_valid
        expect(application.errors[:agent]).to be_present
      end
    end
  end

  describe "grant_type par défaut" do
    it "vaut authorization_code" do
      expect(described_class.new.grant_type).to eq("authorization_code")
    end
  end
end
