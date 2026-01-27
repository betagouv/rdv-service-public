RSpec.describe Users::LoginCodeRequestForm, type: :form_model do
  context "l'usager existe et tout est correct" do
    let!(:user) { create(:user, email: "us@ger.fr") }

    it "le form est valide et la sauvegarde créé le login_code" do
      form = described_class.new(LoginCode.new(email: "us@ger.fr", first_name: "Jean", last_name: "Dupont", domain_id: "RDV_SERVICE_PUBLIC"))
      expect(form).to be_valid
      expect { form.save }.to change(LoginCode, :count).by(1)
    end
  end

  context "l'usager n'existe pas, avec behaviour par défaut (find_existing_user)" do
    it "le form est valide et la sauvegarde créé le login_code" do
      form = described_class.new(LoginCode.new(email: "new@user.fr", first_name: "Nina", last_name: "Personne", domain_id: "RDV_SERVICE_PUBLIC"))
      expect(form).to be_invalid
      expect(form.errors[:base]).to include("Aucun compte usager n’existe pour cet email")
    end
  end

  context "l'usager n'existe pas, avec behaviour :upsert_user" do
    it "le form est valide et la sauvegarde créé le login_code" do
      form = described_class.new(LoginCode.new(email: "new@user.fr", first_name: "Nina", last_name: "Personne", domain_id: "RDV_SERVICE_PUBLIC"), behaviour: "upsert_user")
      expect(form).to be_valid
      expect { form.save }.to change(LoginCode, :count).by(1)
    end
  end

  context "login_code est invalide (email manquant)" do
    specify "le form est invalide" do
      form = described_class.new(LoginCode.new(email: "", first_name: "Jean", last_name: "Dupont", domain_id: "RDV_SERVICE_PUBLIC"))
      expect(form).not_to be_valid
      expect { form.save }.not_to change(LoginCode, :count)
    end
  end

  context "behaviour :upsert_user, login_code est invalide (prénom manquant)" do
    specify "le form est invalide" do
      form = described_class.new(LoginCode.new(email: "us@ger.fr", first_name: "", last_name: "Dupont", domain_id: "RDV_SERVICE_PUBLIC"), behaviour: "upsert_user")
      expect(form).not_to be_valid
      expect(form.errors[:first_name]).to be_present
    end
  end

  context "behaviour :upsert_user, login_code est invalide (nom manquant)" do
    specify "le form est invalide" do
      form = described_class.new(LoginCode.new(email: "us@ger.fr", first_name: "Jean", last_name: "", domain_id: "RDV_SERVICE_PUBLIC"), behaviour: "upsert_user")
      expect(form).not_to be_valid
      expect(form.errors[:last_name]).to be_present
    end
  end

  context "un login code a été généré très récemment" do
    let!(:user) { create(:user, email: "us@ger.fr") }

    before { create(:login_code, email: "us@ger.fr", created_at: 10.seconds.ago) }

    it "ne génère pas un nouveau code et affiche une erreur" do
      form = described_class.new(LoginCode.new(email: "us@ger.fr", first_name: "Jean", last_name: "Dupont", domain_id: "RDV_SERVICE_PUBLIC"))
      expect(form).not_to be_valid
      expect { form.save }.not_to change(LoginCode, :count)
      expect(form.errors[:base]).to be_present
    end
  end
end
