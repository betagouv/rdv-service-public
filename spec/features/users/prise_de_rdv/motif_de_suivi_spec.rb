RSpec.describe "Prise de RDV pour un motif de suivi" do
  let(:now) { Time.zone.parse("2021-12-13 8:00") }

  let!(:user) { create(:user, referent_agents: [agent]) }
  let!(:agent) do
    create(:agent, basic_role_in_organisations: [organisation], services: [service_social, service_insertion]).tap do |agent|
      create(:agent_territorial_access_right, territory: organisation.territory, agent: agent)
    end
  end
  let!(:agent2) { create(:agent) }
  let!(:organisation) { create(:organisation, territory: territory) }
  let!(:territory) do
    create(:territory, departement_number: "92", enable_birth_date_field: true)
  end

  let!(:service_social) { create(:service, name: "Service Social") }
  let!(:service_insertion) { create(:service, name: "Service Insertion") }
  let!(:lieu) { create(:lieu, organisation: organisation) }

  ## follow up motif linked to referent
  let!(:motif1) do
    create(
      :motif,
      name: "RSA Suivi", follow_up: true,
      organisation: organisation, service: service_insertion, restriction_for_rdv: "Instructions pour le RDV"
    )
  end

  ## follow up motif not linked to referent
  let!(:motif2) do
    create(
      :motif,
      name: "RSA suivi téléphonique", follow_up: true, organisation: organisation,
      restriction_for_rdv: nil, service: service_insertion
    )
  end

  ## non follow up motif linked to referent
  let!(:motif3) do
    create(
      :motif,
      name: "RSA Orientation", follow_up: false, organisation: organisation,
      restriction_for_rdv: nil, service: service_insertion
    )
  end

  ## POs
  let!(:plage_ouverture) do
    create(
      :plage_ouverture, :weekdays,
      agent: agent, motifs: [motif1], organisation: organisation, first_day: Time.zone.parse("2021-12-15"), lieu: lieu,
      start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(12)
    )
  end
  let!(:plage_ouverture2) do
    create(
      :plage_ouverture,
      agent: agent2, motifs: [motif2], organisation: organisation, first_day: Time.zone.parse("2021-12-15"), lieu: lieu,
      start_time: Tod::TimeOfDay.new(16), end_time: Tod::TimeOfDay.new(17)
    )
  end
  let!(:plage_ouverture3) do
    create(
      :plage_ouverture, :weekdays,
      agent: agent, motifs: [motif3], organisation: organisation, first_day: Time.zone.parse("2021-12-15"), lieu: lieu,
      start_time: Tod::TimeOfDay.new(14), end_time: Tod::TimeOfDay.new(17)
    )
  end
  # Available PO for selected motif on other agent
  let!(:plage_ouverture4) do
    create(
      :plage_ouverture, :weekdays,
      agent: agent2, motifs: [motif1], organisation: organisation, first_day: Time.zone.parse("2021-12-15"), lieu: lieu,
      start_time: Tod::TimeOfDay.new(14), end_time: Tod::TimeOfDay.new(15)
    )
  end

  ## Collectif follow up motif linked to referent
  let!(:collectif_motif) do
    create(:motif, follow_up: true, restriction_for_rdv: nil, collectif: true, organisation: organisation, service: service_insertion)
  end
  let!(:collectif_rdv) { create(:rdv, motif: collectif_motif, agents: [agent], lieu: lieu, organisation: organisation, starts_at: 2.days.from_now) }

  before { travel_to(now) }
  before { login_as(user, scope: :user) }
  around { |example| perform_enqueued_jobs { example.run } }

  it "shows only the follow up motifs related to the agent", js: true do
    visit users_rdvs_path
    click_link "Prendre un RDV de suivi"

    ### Motif selection
    expect(page).to have_content(motif1.name)
    expect(page).to have_content(collectif_motif.name)

    expect(page).not_to have_content "Pour prendre un RDV avec un de vos agents référent" # Le CTA pour prendre un rdv de suivi ne s'affiche pas

    expect(page).not_to have_content(motif2.name)
    expect(page).not_to have_content(motif3.name)

    find(".fr-card__title", text: /#{motif1.name}/).ancestor(".fr-card__body").find("a").click

    expect(page).to have_content(lieu.name)
    find(".fr-card__title", text: /#{lieu.name}/).ancestor(".fr-card__body").find("button").click
    click_link("Accepter")

    ### Creneau selection
    expect(page).to have_content(agent.last_name.upcase)
    expect(page).to have_content("09:00")
    expect(page).not_to have_content("14:00")

    first(:link, "09:00").click

    ## Formulaire unique : infos usager + confirmation
    expect(page).to have_content("Vos informations")
    click_button("Confirmer mon RDV")

    expect(page).to have_content("Votre RDV")
    expect(page).to have_content(lieu.address)
    expect(page).to have_content(motif1.name)
    expect(page).to have_content("09h00")
  end

  context "when the agent is not the referent" do
    it "shows an error message" do
      visit root_path(referent_ids: [agent2.id], departement: "92", service_id: service_social.id)

      expect(page).not_to have_content(motif1.name)
      expect(page).not_to have_content(collectif_motif.name)
      expect(page).not_to have_content(motif2.name)
      expect(page).not_to have_content(motif3.name)

      expect(page).to have_content("L'agent avec qui vous voulez prendre rendez-vous ne vous est pas assigné comme référent")
    end
  end

  context "when the agent has no PO" do
    let!(:user) { create(:user, referent_agents: [agent3]) }
    let!(:agent3) { create(:agent) }

    it "shows an error message" do
      visit root_path(referent_ids: [agent3.id], departement: "92", service_id: service_social.id)

      expect(page).to have_content("Votre référent n'a pas de créneaux disponibles")
    end
  end
end
