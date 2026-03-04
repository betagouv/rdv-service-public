RSpec.describe Users::UpsertAndLogin do
  let!(:organisation) { create(:organisation) }

  let(:email) { "patricia_duroy@demo.rdv-solidarites.fr" }
  let(:first_name) { "Patricia" }
  let(:last_name) { "Duroy" }

  let(:service) { described_class.new(email:, first_name:, last_name:, organisation:) }

  context "quand il n'existe aucune fiche correspondant à l'e-mail" do

    it "crée une fiche usager" do
      expect { service.perform }.to change(User, :count).by(1)
      created_user = User.last
      expect(created_user).to have_attributes(email:, first_name:, last_name:)
      expect(service.user).to eq(created_user)
    end
  end

  context "quand il existe une fiche usager avec cet e-mail dans l'orga passée" do
    let!(:existing_user) { create(:user, email:, first_name: "Ancien", organisations: [organisation]) }

    # TODO: permettre à l'usager de réutiliser **ou pas** la fiche trouvée ?
    it "retrouve la fiche et met à jour les noms" do
      expect { service.perform }.to change { existing_user.reload.first_name }.from("Ancien").to("Patricia")
      expect(service.user).to eq(existing_user)
    end
  end

  context "quand il existe une fiche usager avec cet e-mail dans une autre orga de l'espace de l'orga passée" do
    let!(:existing_user) { create(:user, email:, first_name: "Ancien", organisations: [create(:organisation, territory: organisation.territory)]) }

    # TODO: permettre à l'usager de réutiliser **ou pas** la fiche trouvée ?
    it "retrouve la fiche et met à jour les noms" do
      expect { service.perform }.to change { existing_user.reload.first_name }.from("Ancien").to("Patricia")
      expect(service.user).to eq(existing_user)
    end
  end

  context "quand il existe une fiche usager avec cet e-mail dans l'orga passée et qu'elle est liée à un sub FranceConnect" do
    let!(:existing_user) { create(:user, email:, first_name: "Ancien", organisations: [organisation]) }

    it "retrouve la fiche et met à jour les noms" do
      expect { service.perform }.not_to change { existing_user.reload.first_name }.from("Ancien")
      expect(service.user).to eq(existing_user)
    end
  end
end
