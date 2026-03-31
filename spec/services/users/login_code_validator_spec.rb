RSpec.describe Users::LoginCodeValidator, type: :service do
  context "code valide et utilisable" do
    let!(:login_code) { create(:login_code, email: "test@example.com", code: "123456") }
    let(:service) { described_class.new(email: "test@example.com", code: "123456") }

    specify do
      expect(service).to be_valid
      expect(service.valid_login_code).to eq(login_code)
    end
  end

  context "le code saisi existe mais a déjà été utilisé" do
    let!(:login_code) { create(:login_code, email: "test@example.com", code: "123456", used_at: 1.minute.ago) }
    let(:service) { described_class.new(email: "test@example.com", code: "123456") }

    specify do
      expect(service).not_to be_valid
      expect(service.error).to eq "Code déjà utilisé, veuillez en demander un nouveau"
    end
  end

  context "le code saisi existe mais est expiré" do
    let!(:login_code) { create(:login_code, email: "test@example.com", code: "123456", created_at: 2.hours.ago) }
    let(:service) { described_class.new(email: "test@example.com", code: "123456") }

    specify do
      expect(service).not_to be_valid
      expect(service.error).to eq "Code expiré, veuillez en demander un nouveau"
      expect(service.should_redirect_to_code_request?).to be true
    end
  end

  context "le code saisi n'existe pas" do
    let(:service) { described_class.new(email: "test@example.com", code: "999999") }

    specify do
      expect(service).not_to be_valid
      expect(service.error).to eq "Code invalide"
      expect(service.should_redirect_to_code_request?).to be true
    end
  end

  context "mauvais code saisi mais un code utilisable existe" do
    let!(:login_code) { create(:login_code, email: "test@example.com", code: "123456") }
    let(:service) { described_class.new(email: "test@example.com", code: "000000") }

    specify do
      expect(service).not_to be_valid
      expect(service.error).to eq "Veuillez renseigner le dernier code qui vous a été envoyé par email, ou attendre quelques instants de le recevoir"
      expect(service.should_redirect_to_code_request?).to be false
    end
  end

  context "code très ancien (plus de 24h)" do
    let!(:login_code) { create(:login_code, email: "test@example.com", code: "123456", created_at: 25.hours.ago) }
    let(:service) { described_class.new(email: "test@example.com", code: "123456") }

    specify do
      expect(service).not_to be_valid
      expect(service.error).to eq "Code invalide"
      expect(service.should_redirect_to_code_request?).to be true
    end
  end
end
