RSpec.describe Users::LoginService, type: :service do
  let(:sign_in_user_lambda) { ->(_user) {} }
  let!(:user) { create(:user, email: "test@example.com") }

  context "code valide et utilisable" do
    let!(:login_code) { create(:login_code, email: "test@example.com", code: "123456") }
    let(:service) { described_class.new(email: "test@example.com", code: "123456", sign_in_user_lambda:) }

    specify do
      expect(sign_in_user_lambda).to receive(:call).with(user)
      expect(service.perform).to be true
      expect(user.reload.already_logged_in?).to be true
      expect(login_code.reload.used?).to be true
    end
  end

  context "le code saisi existe mais a déjà été utilisé" do
    let!(:login_code) { create(:login_code, email: "test@example.com", code: "123456", used_at: 1.minute.ago) }
    let(:service) { described_class.new(email: "test@example.com", code: "123456", sign_in_user_lambda:) }

    specify do
      expect(sign_in_user_lambda).not_to receive(:call)
      expect(service.perform).to be false
      expect(service.error).to eq "Code déjà utilisé, veuillez en demander un nouveau"
      expect(service.should_redirect_to_code_request?).to be true
    end
  end

  context "le code saisi existe mais est expiré" do
    let!(:login_code) { create(:login_code, email: "test@example.com", code: "123456", created_at: 2.hours.ago) }
    let(:service) { described_class.new(email: "test@example.com", code: "123456", sign_in_user_lambda:) }

    specify do
      expect(sign_in_user_lambda).not_to receive(:call)
      expect(service.perform).to be false
      expect(service.error).to eq "Code expiré, veuillez en demander un nouveau"
      expect(service.should_redirect_to_code_request?).to be true
    end
  end

  context "le code saisi n'existe pas" do
    let(:service) { described_class.new(email: "test@example.com", code: "999999", sign_in_user_lambda:) }

    specify do
      expect(sign_in_user_lambda).not_to receive(:call)
      expect(service.perform).to be false
      expect(service.error).to eq "Code invalide"
      expect(service.should_redirect_to_code_request?).to be true
    end
  end

  context "mauvais le code saisi mais un code utilisable existe" do
    let!(:login_code) { create(:login_code, email: "test@example.com", code: "123456") }
    let(:service) { described_class.new(email: "test@example.com", code: "000000", sign_in_user_lambda:) }

    specify do
      expect(sign_in_user_lambda).not_to receive(:call)
      expect(service.perform).to be false
      expect(service.error).to eq "Veuillez renseigner le dernier code qui vous a été envoyé par email, ou attendre quelques instants de le recevoir"
      expect(service.should_redirect_to_code_request?).to be false
    end
  end

  context "code très ancien (plus de 24h)" do
    let!(:login_code) { create(:login_code, email: "test@example.com", code: "123456", created_at: 25.hours.ago) }
    let(:service) { described_class.new(email: "test@example.com", code: "123456", sign_in_user_lambda:) }

    specify do
      expect(sign_in_user_lambda).not_to receive(:call)
      expect(service.perform).to be false
      expect(service.error).to eq "Code invalide"
    end
  end

  context "login code avec nom prénom différents pour un usager existant" do
    let!(:user) { create(:user, email: "test@example.com", first_name: "Martyna", last_name: "Gorski") }
    let!(:login_code) { create(:login_code, email: "test@example.com", code: "123456", created_at: 2.minutes.ago, first_name: "Joana", last_name: "Duri") }
    let(:service) { described_class.new(email: "test@example.com", code: "123456", sign_in_user_lambda:) }

    it "connecte l'usagere et modifie son nom prénom" do
      expect(sign_in_user_lambda).to receive(:call).with(user)
      expect(service.perform).to be true
      expect(user.reload.first_name).to eq("Joana")
      expect(user.reload.last_name).to eq("Duri")
    end
  end

  context "login code avec nom prénom différents pour un usager existant déjà FranceConnecté" do
    let!(:user) { create(:user, :using_france_connect, email: "test@example.com", first_name: "Martyna", last_name: "Gorski") }
    let!(:login_code) { create(:login_code, email: "test@example.com", code: "123456", created_at: 2.minutes.ago, first_name: "Joana", last_name: "Duri") }
    let(:service) { described_class.new(email: "test@example.com", code: "123456", sign_in_user_lambda:) }

    it "connecte l'usagere mais ne modifie pas son nom prénom" do
      expect(sign_in_user_lambda).to receive(:call).with(user)
      expect(service.perform).to be true
      expect(user.reload.first_name).to eq("Martyna")
      expect(user.reload.last_name).to eq("Gorski")
    end
  end
end
