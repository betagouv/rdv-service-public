# frozen_string_literal: true

describe "Agent can organize a rdv collectif", js: true do
  let!(:motif) do
    create(:motif, :collectif, name: "Atelier participatif", organisation: organisation, service: service)
  end
  let(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let!(:lieu) { create(:lieu, organisation: organisation) }

  let!(:user1) { create(:user, organisations: [organisation]) }
  let!(:user2) { create(:user, organisations: [organisation]) }
  let!(:user3) { create(:user, organisations: [organisation]) }

  specify do
    travel_to(Time.zone.local(2022, 3, 14))
    agent = create(:agent, basic_role_in_organisations: [organisation], service: service, first_name: "Alain", last_name: "DIALO")
    login_as(agent, scope: :agent)

    # Creating a new RDV Collectif
    visit authenticated_agent_root_path
    click_link "RDV Collectifs"
    expect(page).to have_content("Aucun RDV")

    click_link "Nouveau RDV Collectif"
    expect(page).to have_content("Choisissez un motif")
    click_link "Atelier participatif"

    expect(page).to have_content("Commence")

    fill_in "Commence à", with: "17/3/2022 14:00"
    fill_in "Durée en minutes", with: "30"
    fill_in "Nombre de places", with: 2
    fill_in "Contexte", with: "Traitement de texte"

    select("DIALO Alain", from: "rdv_agent_ids")
    select(lieu.name, from: "Lieu")
    click_button "Enregistrer"

    expect(page).to have_content("Atelier participatif créé")

    expect(page).to have_content("Jeudi 17 mars à 14:00")
    expect(page).to have_content("2 places disponibles")

    click_link("Ajouter un participant")
    add_user(user1)
    click_button "Enregistrer"

    expect(page).to have_content("1 places disponibles")

    click_link("Ajouter un participant")
    add_user(user2)
    click_button "Enregistrer"

    expect(page).to have_content("Complet")

    click_link "Atelier participatif : Traitement de texte"

    add_user(user3)
    click_button "Enregistrer"

    expect(page).to have_content("Trop de participants (3 personnes pour 2 places)")
    click_link "Trop de participants (3 personnes pour 2 places)"

    fill_in "Nombre de places", with: ""
    click_button "Enregistrer"

    expect(page).to have_content("Ajouter un participant")
    expect(page).to have_content("Pas de limite de places")
    expect(page).to have_content("3 participants")

    click_link "Atelier participatif : Traitement de texte"

    accept_confirm do
      click_link "Supprimer ce RDV"
    end
    expect(page).to have_content("Le rendez-vous a été supprimé.")
  end
end
