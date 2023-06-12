# frozen_string_literal: true

describe "Admin can configure the organisation" do
  let!(:organisation) { create(:organisation) }
  let!(:pmi) { create(:service, name: "PMI") }
  let!(:service_social) { create(:service, name: "Service social") }
  let!(:agent_admin) { create(:agent, first_name: "Jeanne", last_name: "Dupont", email: "jeanne.dupont@love.fr", service: pmi, admin_role_in_organisations: [organisation]) }
  let!(:agent_user) { create(:agent, first_name: "Tony", last_name: "Patrick", email: "tony@patrick.fr", service: pmi, basic_role_in_organisations: [organisation], invitation_accepted_at: nil) }
  let!(:other_agent_user) { create(:agent, first_name: "JP", last_name: "Dupond", email: "jp@dupond.fr", service: service_social, basic_role_in_organisations: [organisation]) }
  let!(:motif) { create(:motif, name: "Motif 1", service: pmi, organisation: organisation) }
  let!(:user) { create(:user, organisations: [organisation]) }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let!(:secretariat) { create(:service, :secretariat) }
  let(:le_nouveau_motif) { build(:motif, name: "Motif 2", service: pmi, organisation: organisation) }
  let(:la_nouvelle_org) { build(:organisation) }

  around { |example| perform_enqueued_jobs { example.run } }

  before do
    login_as(agent_admin, scope: :agent)
    visit authenticated_agent_root_path
  end

  it "CRUD on lieux" do
    click_link "Lieux"
    expect_page_title("Vos lieux de consultation")

    within("#lieu_#{lieu.id}") do
      click_link "Modifier"
    end

    expect_page_title("Modifier le lieu")
    fill_in "Nom", with: "Le nouveau lieu"
    fill_in "Téléphone", with: "01 02 03 04 05"
    click_button("Enregistrer")

    expect_page_title("Vos lieux de consultation")

    nouveau_lieu = Lieu.find_by(name: "Le nouveau lieu")
    within("#lieu_#{nouveau_lieu.id}") do
      click_link "Modifier"
    end

    click_link("Supprimer")

    expect_page_title("Vos lieux de consultation")
    expect_page_with_no_record_text("Vous n'avez pas encore ajouté de lieu de consultation.")

    click_link "Ajouter un lieu", match: :first

    expect_page_title("Nouveau lieu")
    fill_in "Nom", with: "Un autre nouveau lieu"
    fill_in "Adresse", with: "3 Place de la Gare, Strasbourg, 67000, 67, Bas-Rhin, Grand Est"
    first("input#lieu_latitude", visible: false).set(48.583844)
    first("input#lieu_longitude", visible: false).set(7.735253)
    click_button "Enregistrer"
    expect_page_title("Vos lieux de consultation")

    le_nouveau_lieu = Lieu.find_by(name: "Un autre nouveau lieu")
    within("#lieu_#{le_nouveau_lieu.id}") do
      click_link "Modifier"
    end
  end

  it "CRUD on agents" do
    click_link "Agents"
    expect_page_title("Agents de Organisation n°1")

    click_link "PATRICK Tony"
    expect_page_title("Modifier le rôle de l'agent Tony PATRICK")
    choose :agent_role_access_level_admin
    click_button("Enregistrer")

    expect_page_title("Agents de Organisation n°1")
    expect(page).to have_content("Admin", count: 2)

    click_link "PATRICK Tony"
    click_link("Supprimer le compte")

    expect_page_title("Invitations en cours pour Organisation n°1")
    expect(page).to have_no_content("Tony PATRICK")

    click_link "Inviter un agent", match: :first
    fill_in "Email", with: "jean@paul.com"
    click_button "Envoyer une invitation"

    expect_page_title("Invitations en cours pour Organisation n°1")
    expect(page).to have_content("jean@paul.com")

    open_email("jean@paul.com")
    expect(current_email.subject).to eq "Vous avez été invité sur RDV Solidarités"
  end

  context "when the organisation is using rdv_aide_numerique verticale" do
    let!(:organisation) { create(:organisation, verticale: :rdv_aide_numerique) }

    it "allows inviting agents on the correct domain" do
      click_link "Agents"
      click_link "Inviter un agent", match: :first
      fill_in "Email", with: "jean@paul.com"
      click_button "Envoyer une invitation"

      open_email("jean@paul.com")
      expect(current_email.subject).to eq "Vous avez été invité sur RDV Aide Numérique"
      expect(current_email.body).to include "rejoindre RDV Aide Numérique"
    end
  end

  context "when the organisation is using rdv_insertion verticale" do
    let!(:organisation) { create(:organisation, verticale: :rdv_insertion) }

    it "allows inviting agents on the correct domain" do
      click_link "Agents"
      click_link "Inviter un agent", match: :first
      fill_in "Email", with: "jean@paul.com"
      click_button "Envoyer une invitation"

      open_email("jean@paul.com")
      expect(current_email.subject).to eq "Vous avez été invité sur RDV Solidarités"
    end
  end

  it "Update organisation" do
    click_link "Organisation"
    click_link "Modifier"
    fill_in "Nom", with: la_nouvelle_org.name
    fill_in "Téléphone", with: la_nouvelle_org.phone_number
    fill_in "Horaires", with: la_nouvelle_org.horaires
    click_button "Enregistrer"

    expect(page).to have_content("L’organisation a été modifiée.")
  end

  it "CRUD on motifs", js: true do
    click_link "Paramètres"
    click_link "Motifs"
    expect_page_title("Vos motifs")

    click_link motif.name
    expect(page).to have_content("Motif 1")
    click_link "Éditer"
    fill_in :motif_name, with: "Être appelé par"
    click_button("Enregistrer")
    expect(page).to have_content("Être appelé par")
    expect(page).to have_selector("h3", text: "Être appelé par (PMI)")

    click_link "Motifs"
    click_link "Être appelé par"
    expect(page).to have_content("Être appelé par")
    click_link("Supprimer")
    begin
      page.driver.browser.switch_to.alert.accept
    rescue Selenium::WebDriver::Error::NoSuchAlertError
      click_link("Supprimer")
      retry
    end

    expect_page_title("Vos motifs")
    expect(page).to have_content("Vous n'avez pas encore créé de motif.")

    click_link "Créer un motif", match: :first
    expect(page).to have_content("Nouveau motif")
    ## Check secretariat is unavailable
    expect(page.all("select#motif_service_id option").map(&:value)).to match_array ["", pmi.id.to_s, service_social.id.to_s]
    select(service_social.name, from: :motif_service_id)
    fill_in :motif_name, with: "truc"
    fill_in "Couleur", with: le_nouveau_motif.color
    click_button "Enregistrer"
    expect(page).to have_link("truc")
  end
end
