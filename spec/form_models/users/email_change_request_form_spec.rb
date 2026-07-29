RSpec.describe Users::EmailChangeRequestForm, type: :form_model do
  context "la nouvelle adresse est valide et différente de l'actuelle" do
    let(:current_user) { create(:user, email: "ancienne@adresse.fr") }

    it "créé le login_code" do
      form = described_class.new(email: "nouvelle@adresse.fr", current_user:, domain_id: "RDV_SERVICE_PUBLIC")
      expect(form).to be_valid
      expect { form.save }.to change(LoginCode, :count).by(1)
    end
  end

  context "la nouvelle adresse est identique à l'adresse actuelle" do
    let(:current_user) { create(:user, email: "ancienne@adresse.fr") }

    specify do
      form = described_class.new(email: "ancienne@adresse.fr", current_user:, domain_id: "RDV_SERVICE_PUBLIC")
      expect(form).not_to be_valid
      expect(form.errors[:base]).to include("La nouvelle adresse email doit être différente de l’adresse actuelle")
    end
  end

  context "la nouvelle adresse a une casse différente de l'adresse actuelle" do
    let(:current_user) { create(:user, email: "ancienne@adresse.fr") }

    specify do
      form = described_class.new(email: "ANCIENNE@adresse.fr", current_user:, domain_id: "RDV_SERVICE_PUBLIC")
      expect(form).not_to be_valid
      expect(form.errors[:base]).to include("La nouvelle adresse email doit être différente de l’adresse actuelle")
    end
  end

  context "email invalide (format incorrect)" do
    let(:current_user) { create(:user, email: "ancienne@adresse.fr") }

    specify do
      form = described_class.new(email: "pas-un-email", current_user:, domain_id: "RDV_SERVICE_PUBLIC")
      expect(form).not_to be_valid
      expect { form.save }.not_to change(LoginCode, :count)
    end
  end

  context "l'usager ne peut pas changer son email (connecté via FranceConnect)" do
    let(:current_user) { create(:user, :using_france_connect, email: "ancienne@adresse.fr") }

    it "le form est invalide" do
      form = described_class.new(email: "nouvelle@adresse.fr", current_user:, domain_id: "RDV_SERVICE_PUBLIC")
      expect(form).not_to be_valid
      expect(form.errors[:base]).to include("Vous ne pouvez pas modifier votre adresse email.")
      expect { form.save }.not_to change(LoginCode, :count)
    end
  end

  context "un code a été généré très récemment pour cette adresse" do
    let(:current_user) { create(:user, email: "ancienne@adresse.fr") }

    before { create(:login_code, email: "nouvelle@adresse.fr", created_at: 10.seconds.ago) }

    it "ne génère pas un nouveau code et affiche une erreur" do
      form = described_class.new(email: "nouvelle@adresse.fr", current_user:, domain_id: "RDV_SERVICE_PUBLIC")
      expect(form).not_to be_valid
      expect { form.save }.not_to change(LoginCode, :count)
      expect(form.errors[:base]).to be_present
    end
  end
end
