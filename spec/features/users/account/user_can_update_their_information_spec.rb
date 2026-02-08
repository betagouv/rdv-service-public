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
      click_on("Enregistrer")
      expect(page).to have_content "Vos informations ont été mises à jour."
      expect(user.reload.affiliation_number).to eq "123"
    end
  end

  describe "birth_name field" do
    before { visit users_informations_path }

    context "sur le domaine RDV Solidarités" do
      it "affiche le champ nom de naissance" do
        expect(page).to have_field("Nom de naissance")
      end
    end

    context "quand l'usager est connecté via ProConnect" do
      let(:user) { create(:user, pro_connect_openid_sub: "fake_sub", organisations: [organisation]) }

      it "n'affiche pas le champ nom de naissance" do
        expect(page).not_to have_field("Nom de naissance")
      end
    end

    context "quand l'usager est connecté via FranceConnect" do
      let(:user) { create(:user, :using_france_connect, organisations: [organisation]) }

      it "affiche le champ nom de naissance en lecture seule" do
        expect(page).to have_field("Nom de naissance", disabled: true)
      end
    end
  end

  describe "first_name and last_name fields" do
    before do
      visit users_informations_path
    end

    context "quand l'usager est connecté via FranceConnect" do
      let(:user) { create(:user, :using_france_connect, organisations: [organisation]) }

      it "affiche le prénom en lecture seule et le nom modifiable" do
        expect(page).to have_field("Prénom", disabled: true)
        expect(page).to have_field("Nom", disabled: false)
      end
    end

    context "quand l'usager est connecté via ProConnect" do
      let(:user) { create(:user, pro_connect_openid_sub: "fake_sub", organisations: [organisation]) }

      it "affiche le prénom et le nom en lecture seule" do
        expect(page).to have_field("Prénom", disabled: true)
        expect(page).to have_field("Nom", disabled: true)
      end
    end
  end

  describe "FranceConnect frozen fields warning" do
    context "quand l'usager est connecté via FranceConnect" do
      let(:user) { create(:user, :using_france_connect, organisations: [organisation]) }

      it "affiche le warning FranceConnect" do
        visit users_informations_path
        expect(page).to have_content("Les champs d'état civil ne peuvent plus être modifiés suite à la connexion certifiée par FranceConnect")
      end
    end

    context "quand l'usager n'est pas connecté via FranceConnect" do
      it "n'affiche pas le warning FranceConnect" do
        visit users_informations_path
        expect(page).not_to have_content("Les champs d'état civil ne peuvent plus être modifiés")
      end
    end
  end

  describe "landline phone number warning" do
    context "quand l'usager a un numéro fixe" do
      let(:user) { create(:user, phone_number: "0130303030", organisations: [organisation]) }

      it "affiche le warning numéro non-mobile" do
        visit users_informations_path
        expect(page).to have_content("Vous ne recevrez pas de SMS avec ce numéro non-mobile")
      end
    end

    context "quand l'usager a un numéro mobile" do
      let(:user) { create(:user, phone_number: "0612345678", organisations: [organisation]) }

      it "n'affiche pas le warning" do
        visit users_informations_path
        expect(page).not_to have_content("Vous ne recevrez pas de SMS avec ce numéro non-mobile")
      end
    end
  end

  describe "updating notification_email" do
    context "when the user is connected with FranceConnect" do
      let(:user) { create(:user, :using_france_connect, organisations: [organisation]) }

      it "allows changing the notification email" do
        visit users_informations_path
        fill_in("Email de notification", with: "nouvelle.adresse@exemple.fr")
        click_on("Enregistrer")
        expect(page).to have_content "Vos informations ont été mises à jour."
        expect(user.reload.notification_email).to eq "nouvelle.adresse@exemple.fr"
      end
    end
  end
end
