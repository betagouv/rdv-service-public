# frozen_string_literal: true

describe "CNFS agent can configure online booking" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, :cnfs, admin_role_in_organisations: [organisation]) }

  before do
    login_as(agent, scope: :agent)

    create(:motif, organisation: organisation, service: agent.service, reservable_online: false, collectif: false, name: "Motif individuel fermé sans plages d'ouverture")
    create(:motif, organisation: organisation, service: agent.service, reservable_online: true, collectif: false, name: "Motif individuel ouvert sans plages d'ouverture")

    motif = create(:motif, organisation: organisation, service: agent.service, reservable_online: false, collectif: false, name: "Motif individuel fermé avec plages d'ouverture")
    create(:plage_ouverture, motifs: [motif], agent: agent, organisation: organisation)

    motif = create(:motif, organisation: organisation, service: agent.service, reservable_online: true, collectif: false, name: "Motif individuel ouvert avec plages d'ouverture")
    create(:plage_ouverture, motifs: [motif], agent: agent, organisation: organisation)

    create(:motif, organisation: organisation, service: agent.service, reservable_online: false, collectif: false, name: "Motif collectif fermé sans créneaux")

    motif = create(:motif, organisation: organisation, service: agent.service, reservable_online: true, collectif: false, name: "Motif collectif ouvert avec créneaux")
    create(:rdv, motif: motif, max_participants_count: 5)
  end

  it "displays the information of the various motifs" do
    visit admin_organisation_online_booking_path(organisation)
    expect(page).to have_css('[data-clipboard-target="copy-button"]')
    expect(page).to have_content("adsfasdf") # TODO
    # vérifier que les liens de petits cta vont sur les bonnes pages préremplies correctement
  end
end
