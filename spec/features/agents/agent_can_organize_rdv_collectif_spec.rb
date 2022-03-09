require "rails_helper"

describe "Agent can organize a rdv collectif", js: true do
  # Pour une orga avec un motif collectif
  # Créer un rdv avec limite de participants à 2
  # Ajouter un participant
  # Vérifier affichage
  # Ajouter un autre participant
  # Vérifier affichage
  # Ajouter un participant en trop via l’interface edit
  # Vérifier l’affichage
  # Enlever le participant en trop
  # Vérifier affichage
  # Enlever la limite de places
  # Vérifier affichage
  # Supprimer le rdv
  let!(:motif) do
    create(:motif, :collectif, name: "Atelier participatif", organisation: organisation, service: service)
  end
  let(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }

  specify do
    agent = create(:agent, basic_role_in_organisations: [organisation], service: service)
    login_as(agent, scope: :agent)

    # Creating a new RDV Collectif
    visit authenticated_agent_root_path
    click_link "RDV Collectifs"
    expect(page).to have_content("Aucun RDV")

    click_link "Nouveau RDV Collectif"
    expect(page).to have_content("Choisissez un motif")
    click_link "Atelier participatif"
  end
end
