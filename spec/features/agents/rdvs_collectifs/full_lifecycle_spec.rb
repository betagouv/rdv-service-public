RSpec.describe "Agent can organize a rdv collectif", :js do
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation], service: service, first_name: "Alain", last_name: "DIALO") }
  let!(:motif) do
    create(:motif, :collectif, name: "Atelier participatif", organisation: organisation, service: service)
  end
  let(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let!(:lieu) { create(:lieu, organisation: organisation) }

  let!(:user1) { create(:user, organisations: [organisation]) }
  let!(:user2) { create(:user, organisations: [organisation]) }

  before do
    stub_netsize_ok
    travel_to(Time.zone.local(2022, 3, 14))
    login_as(agent, scope: :agent)
  end

  around { |example| perform_enqueued_jobs { example.run } }

  def create_rdv_collectif(lieu_availability)
    # Creating a new RDV Collectif
    visit admin_organisation_rdvs_collectifs_path(organisation)
    expect(page).to have_content("Aucun RDV")

    click_link "Nouveau RDV Collectif"
    expect(page).to have_content("Choisissez un motif")
    click_link "Atelier participatif"

    expect(page).to have_content("Commence")

    fill_in "Commence à", with: "17/3/2022 14:00"
    fill_in "Durée en minutes", with: "30"
    fill_in "Nombre de places", with: 4
    fill_in "Intitulé", with: "Traitement de texte"

    select("DIALO Alain", from: "rdv_agent_ids")

    if lieu_availability == :enabled
      select(lieu.name, from: "rdv_lieu_id")

    else
      click_link("Définir un lieu ponctuel.")
      fill_in :rdv_lieu_attributes_name, with: "Café de la gare"
      fill_in "Adresse", with: "3 Place de la Gare, Strasbourg, 67000"
      page.execute_script("document.querySelector('input#rdv_lieu_attributes_latitude').value = '48.583844'")
      page.execute_script("document.querySelector('input#rdv_lieu_attributes_longitude').value = 7.735253")
    end

    click_button "Enregistrer"
    expect(page).to have_content("Le rendez-vous a été créé")
    expect(page).to have_content("Jeudi 17 mars à 14:00")
    expect(page).to have_content("4 places restantes")

    click_link("Ajouter un participant")
    add_user(user1)
    add_new_user
    click_button "Enregistrer"

    expect(Receipt.where(user_id: user1.id, channel: "sms", result: "delivered").count).to eq 1
    expect(Receipt.where(user_id: user1.id, channel: "mail", result: "processed").count).to eq 1

    expect(page).to have_content("2 places restantes")

    click_link("Ajouter un participant")
    add_user(user2)
    add_new_user({ with_phone: true })
    click_button "Enregistrer"
    user3 = User.last

    expect(user3).not_to eq user2
    expect(Receipt.where(user_id: user2.id, channel: "sms", result: "delivered").count).to eq 1
    expect(Receipt.where(user_id: user2.id, channel: "mail", result: "processed").count).to eq 1
    expect(Receipt.where(user_id: user3.id, channel: "sms", result: "delivered").count).to eq 1

    expect(page).to have_content("Complet")
    expect(page).not_to have_content("Ajouter un participant")
  end

  context "create a RDV collectif an existing lieu" do
    it do
      create_rdv_collectif(:enabled)
    end
  end

  context "create a RDV collectif an single_use lieu" do
    it do
      create_rdv_collectif(:single_use)
    end
  end

  describe "warnings" do
    it "shows a warning when the name is too long" do
      # Creating a new RDV Collectif
      visit admin_organisation_rdvs_collectifs_path(organisation)
      expect(page).to have_content("Aucun RDV")

      click_link "Nouveau RDV Collectif"
      expect(page).to have_content("Choisissez un motif")
      click_link "Atelier participatif"

      expect(page).to have_content("Commence")

      fill_in "Commence à", with: "17/3/2022 14:00"
      fill_in "Durée en minutes", with: "30"
      fill_in "Nombre de places", with: 4
      fill_in "Intitulé", with: "Organiser ses fichiers et ses dossiers sur son ordinateur"

      select("DIALO Alain", from: "rdv_agent_ids")
      select(lieu.name, from: "rdv_lieu_id")

      click_button "Enregistrer"
      expect(page).to have_content("L'intitulé est trop long et sera abrégé ainsi dans les notifications SMS : Organiser ses fichiers et ses dossiers sur son ord...")
    end
  end
end
