RSpec.describe EspaceOperateurANCT do
  let(:siret) { "21550050500015" }
  let(:account_email) { "contact@mairie-nantes.fr" }

  stub_env_with(ESPACE_OPERATEUR_ANCT_AUTH_TOKEN: "Bearer fake-token")

  describe "#organization, #operator, #entitlements" do
    subject(:service) { described_class.new(siret, account_email) }

    around do |example|
      VCR.use_cassette("espace_operateur_anct/entitlements_success") { example.run }
    end

    it "retourne l'organisation" do
      expect(service.organization).to be_present
    end

    it "retourne l'opérateur" do
      expect(service.operator).to be_present
    end

    it "retourne les entitlements" do
      expect(service.entitlements).to be_present
    end

    it "n'appelle l'API qu'une fois pour plusieurs méthodes" do
      service.organization
      service.operator
      service.entitlements
      expect(WebMock).to have_requested(:get, /entitlements/).once
    end
  end

  describe "#can_access?" do
    subject { described_class.new(siret, account_email).can_access? }

    context "quand l'utilisateur a accès" do
      around { |ex| VCR.use_cassette("espace_operateur_anct/entitlements_success") { ex.run } }

      it { is_expected.to be true }
    end

    context "quand l'utilisateur n'a pas accès" do
      let(:siret) { "21350238800019" }

      around { |ex| VCR.use_cassette("espace_operateur_anct/entitlements_no_access") { ex.run } }

      it { is_expected.to be false }
    end

    context "quand l'API retourne une erreur" do
      subject { described_class.new(siret, account_email, "aienrustesr").can_access? }

      around { |ex| VCR.use_cassette("espace_operateur_anct/entitlements_api_error") { ex.run } }

      it { is_expected.to be false }
    end
  end

  describe "#admin?" do
    subject { described_class.new(siret, account_email).admin? }

    context "quand l'utilisateur est admin" do
      around { |ex| VCR.use_cassette("espace_operateur_anct/entitlements_admin") { ex.run } }

      let(:account_email) { "test-admin@example.com" }

      it { is_expected.to be true }
    end

    context "quand l'utilisateur n'est pas admin" do
      around { |ex| VCR.use_cassette("espace_operateur_anct/entitlements_success") { ex.run } }

      it { is_expected.to be false }
    end
  end

  describe "initialize" do
    context "sans token d'authentification configuré" do
      stub_env_with(ESPACE_OPERATEUR_ANCT_AUTH_TOKEN: nil)

      it "lève une exception" do
        expect { described_class.new(siret, account_email) }
          .to raise_error("Ce service n’est pas utilisable dans cet environnement.")
      end
    end
  end
end
