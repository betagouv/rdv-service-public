# frozen_string_literal: true

RSpec.describe "motifs for prescripteurs only" do
  let(:organisation) { create(:organisation, territory: territory_with_beta_prescripteur_enabled) }
  let(:territory_with_beta_prescripteur_enabled) { create(:territory, departement_number: "83") }
  let(:lieu) { create(:lieu, organisation: organisation, name: "Bureau") }
  let(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
  let(:motif) { create(:motif, name: "Accompagnement individuel", organisation: organisation, bookable_by: :agents) }

  before do
    login_as(agent, scope: :agent)
  end

  specify "setting a motif as prescripteurs only from the agents form", js: true do
    visit edit_admin_organisation_motif_path(organisation, motif)
    expect(page).not_to have_content("Délai minimum de réservation")

    choose("Ouvert aux agents et aux prescripteurs")
    expect(page).to have_content("Délai minimum de réservation")
  end
end
