RSpec.describe "Admin can configure the organisation" do
  let!(:organisation) { create(:organisation, name: "MDS Montreuil Nord") }
  let!(:agent_admin) { create(:agent, admin_role_in_organisations: [organisation]) }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let(:la_nouvelle_org) { build(:organisation) }

  before do
    login_as(agent_admin, scope: :agent)
    visit authenticated_agent_root_path
  end

  it "CRUD on lieux" do
    click_link "Configuration"
    click_link "Lieux"
    expect_page_title("Lieux")

    within("#lieu_#{lieu.id}") do
      click_link "Modifier"
    end

    expect_page_title("Modifier le lieu")
    fill_in "Nom", with: "Le nouveau lieu"
    fill_in "Téléphone", with: "01 02 03 04 05"
    click_button("Enregistrer")

    expect_page_title("Lieux")

    nouveau_lieu = Lieu.find_by(name: "Le nouveau lieu")
    within("#lieu_#{nouveau_lieu.id}") do
      click_link "Modifier"
    end

    click_link("Fermer ce lieu")
    expect_page_title("Lieux")

    expect(nouveau_lieu.reload).to have_attributes(availability: "disabled")

    expect(page).to have_content("Le lieu a été fermé.")

    click_on("Le nouveau lieu")
    expect(page).to have_content("Ce lieu est fermé")

    click_link("Réouvrir ce lieu")
    expect(page).to have_content("Le lieu a été rouvert.")
    expect(nouveau_lieu.reload).to have_attributes(availability: "enabled")

    nouveau_lieu.update!(availability: :disabled)

    click_on("Le nouveau lieu")
    click_link("Supprimer")

    expect_page_title("Lieux")
    expect(page).to have_content("Vous n'avez pas encore ajouté de lieu de consultation.")

    click_link "Ajouter un lieu", match: :first

    expect_page_title("Nouveau lieu")
    fill_in "Nom", with: "Un autre nouveau lieu"
    fill_in "Adresse", with: "3 Place de la Gare, Strasbourg, 67000"
    first("input#lieu_latitude", visible: false).set(48.583844)
    first("input#lieu_longitude", visible: false).set(7.735253)
    click_button "Enregistrer"
    expect_page_title("Lieux")

    le_nouveau_lieu = Lieu.find_by(name: "Un autre nouveau lieu")
    within("#lieu_#{le_nouveau_lieu.id}") do
      click_link "Modifier"
    end
  end

  it "Update organisation contact information" do
    click_link "Configuration"
    click_link "Informations de l'organisation"
    click_link "Modifier"
    fill_in "Nom", with: la_nouvelle_org.name
    fill_in "Téléphone", with: la_nouvelle_org.phone_number
    fill_in "Horaires", with: la_nouvelle_org.horaires
    click_button "Enregistrer"

    expect(page).to have_content("Les informations de contact ont été modifiées")
  end

  describe "link to configuration from other applications" do
    context "when the agent is not an admin of any organisation" do
      let!(:agent_admin) { create(:agent, admin_role_in_organisations: []) }

      it "redirects to the home page" do
        visit("/admin/organisations/configuration")
        expect(page).to have_content "Bienvenue"

        expect(page).to have_current_path("/")
      end
    end

    context "when the agent is the admin of only one organisation" do
      let!(:agent_admin) { create(:agent, admin_role_in_organisations: [organisation], basic_role_in_organisations: [create(:organisation)]) }

      it "redirects to the organisation" do
        visit("/admin/organisations/configuration")
        expect(page).to have_content "Configuration"
        expect(page).to have_current_path(admin_organisation_configuration_path(organisation))
      end
    end

    context "when the agent is the admin of multiple organisations" do
      let!(:agent_admin) do
        create(:agent, admin_role_in_organisations: [organisation, other_organisation])
      end
      let(:other_organisation) { create(:organisation, name: "MDS Montreuil Sud") }

      it "lets the agent choose the organisation, and redirects there" do
        visit("/admin/organisations/configuration")
        expect(page).to have_content(organisation.name)
        expect(page).to have_content(other_organisation.name)
        click_on(other_organisation.name)
        expect(page).to have_content "Configuration"
        expect(page).to have_current_path(admin_organisation_configuration_path(other_organisation))
      end
    end
  end
end
