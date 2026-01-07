RSpec.describe Users::LoginCodeRequestForm, type: :form_model do
  context "l’usager existe et tout est correct" do
    let!(:user) { create(:user, email: "us@ger.fr") }

    it "le form est valide et la sauvegarde créé le login_code" do
      form = described_class.new(LoginCode.new(email: "us@ger.fr", domain_id: Domain::RDV_SERVICE_PUBLIC.id))
      expect(form).to be_valid
      expect { form.save }.to change(LoginCode, :count).by(1)
    end
  end

  context "login_code est invalide" do
    specify "le form est invalide" do
      form = described_class.new(LoginCode.new(email: "", domain_id: Domain::RDV_SERVICE_PUBLIC.id))
      expect(form).not_to be_valid
      expect { form.save }.not_to change(LoginCode, :count)
    end
  end

  context "l’usager n’existe pas" do
    specify do
      form = described_class.new(LoginCode.new(email: "us@ger.fr", domain_id: Domain::RDV_SERVICE_PUBLIC.id))
      expect(form).not_to be_valid
      expect(form.errors[:base].first).to include(/aucun compte usager n’existe/i)
      expect(form.errors[:base].first).not_to include(/si vous souhaitez vous connecter en tant qu’agent/i)
    end
  end

  context "l’usager n’existe pas mais un compte agent existe pour cet email" do
    let!(:agent) { create(:agent, email: "us@ger.fr") }

    specify do
      form = described_class.new(LoginCode.new(email: "us@ger.fr", domain_id: Domain::RDV_SERVICE_PUBLIC.id))
      expect(form).not_to be_valid
      expect(form.errors[:base].first).to include(/aucun compte usager n’existe/i)
      expect(form.errors[:base].first).to include(/si vous souhaitez vous connecter en tant qu’agent/i)
    end
  end
end
