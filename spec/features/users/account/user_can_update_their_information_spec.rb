RSpec.describe "User can update their information" do
  let!(:organisation) { create(:organisation, territory: territory) }
  let(:user) { create(:user, organisations: [organisation]) }
  let(:territory) { create(:territory) }

  before { login_as(user, scope: :user) }

  describe "optional fields" do
    let(:territory) do
      create(:territory, enable_caisse_affiliation_field: true,
                         enable_affiliation_number_field: true, enable_number_of_children_field: false)
    end

    before do
      visit root_path
      click_link "Vos informations"
    end

    it "shows the user information" do
      expect(page).to have_content "Mes informations"
      expect(page).not_to have_content "Nombre d'enfants"
      select "MSA", from: "Caisse d'affiliation"
      fill_in "Numéro d'allocataire", with: 123
      click_on("Modifier")
      expect(page).to have_content "Vos informations ont été mises à jour."
      expect(user.reload.affiliation_number).to eq "123"
    end
  end

  describe "updating notification_email" do
    context "when the user is connected with FranceConnect" do
      let(:user) { create(:user, :using_france_connect, organisations: [organisation]) }

      it "allows changing the notification email" do
        visit users_informations_path
        fill_in("Email de notification", with: "nouvelle.adresse@exemple.fr")
        click_on("Modifier")
        expect(page).to have_content "Vos informations ont été mises à jour."
        expect(user.reload.notification_email).to eq "nouvelle.adresse@exemple.fr"
      end
    end
  end
end
