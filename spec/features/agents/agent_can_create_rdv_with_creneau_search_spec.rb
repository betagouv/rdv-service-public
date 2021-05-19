# frozen_string_literal: true

describe "Agent can create a Rdv with creneau search" do
  include UsersHelper

  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let!(:agent) { create(:agent, first_name: "Alain", last_name: "Tiptop", service: service, basic_role_in_organisations: [organisation]) }
  let!(:agent2) { create(:agent, first_name: "Robert", last_name: "Voila", service: service, basic_role_in_organisations: [organisation]) }
  let!(:agent3) { create(:agent, first_name: "Michel", last_name: "Lapin", service: service, basic_role_in_organisations: [organisation]) }
  let!(:motif) { create(:motif, reservable_online: true, service: service, organisation: organisation) }
  let!(:user) { create(:user, organisations: [organisation]) }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let!(:plage_ouverture) { create(:plage_ouverture, :daily, first_day: Date.new(2019, 7, 22), motifs: [motif], lieu: lieu, agent: agent, organisation: organisation) }
  let!(:lieu2) { create(:lieu, organisation: organisation) }
  let!(:plage_ouverture2) { create(:plage_ouverture, :daily, first_day: Date.new(2019, 7, 22), motifs: [motif], lieu: lieu2, agent: agent2, organisation: organisation) }
  let!(:plage_ouverture3) { create(:plage_ouverture, :daily, first_day: Date.new(2019, 7, 22), motifs: [motif], lieu: lieu, agent: agent3, organisation: organisation) }

  before do
    travel_to(Time.zone.local(2019, 7, 22))
    login_as(agent, scope: :agent)
    visit admin_organisation_agent_agenda_path(organisation, agent)

    click_link("Trouver un créneau")
  end

  after { travel_back }

  it "default", js: true do
    expect_page_title("Choisir un créneau")
    select(motif.name, from: "motif_id")
    click_button("Afficher les créneaux")

    # Display results for both lieux
    expect(page).to have_content(plage_ouverture.lieu.address)
    expect(page).to have_content(plage_ouverture2.lieu.address)
    expect(page).to have_content(plage_ouverture.agent.short_name)
    expect(page).to have_content(plage_ouverture2.agent.short_name)
    expect(page).to have_content(plage_ouverture3.agent.short_name)

    # Add a filter on lieu
    select(lieu.name, from: "lieu_ids")
    click_button("Afficher les créneaux")
    expect(page).to have_content(plage_ouverture.lieu.address)
    expect(page).to have_content(plage_ouverture3.agent.short_name)
    expect(page).not_to have_content(plage_ouverture2.lieu.address)

    # Add an agent filter
    select(agent.full_name, from: "agent_ids")
    click_button("Afficher les créneaux")
    expect(page).to have_content(plage_ouverture.agent.short_name)
    expect(page).not_to have_content(plage_ouverture2.agent.short_name)
    expect(page).not_to have_content(plage_ouverture3.agent.short_name)

    # Click to change to next week
    first(:link, ">>").click
    expect(page).to have_content("<<", wait: 5)

    expect(page).to have_content(plage_ouverture.agent.short_name)
    expect(page).not_to have_content(plage_ouverture2.agent.short_name)
    expect(page).not_to have_content(plage_ouverture3.agent.short_name)

    # Select creneau
    first(:link, "09:30").click

    # Step 2
    expect_page_title("Créer RDV 2/4")
    expect(page).to have_selector(".card-title", text: "2. Usager(s)")
    expect(page).to have_selector(".list-group-item", text: /Motif/)
    select_user(user)
    click_button("Continuer")

    # Step 3
    expect_page_title("Créer RDV 3/4")
    expect(page).to have_selector(".card-title", text: "3. Agent(s), horaires & lieu")
    expect(page).to have_selector(".list-group-item", text: /Usager\(s\)/)
    expect(page).to have_selector(".list-group-item", text: /Motif/)
    expect(find_field("rdv[lieu_id]").value).to eq(lieu.id.to_s)
    click_button("Continuer")

    # Step 4
    expect_page_title("Créer RDV 4/4")
    expect(page).to have_selector(".card-title", text: "4. Notifications")
    expect(page).to have_selector(".list-group-item", text: /Motif/)
    expect(page).to have_selector(".list-group-item", text: /Usager\(s\)/)
    expect(page).to have_selector(".list-group-item", text: /Agent\(s\), horaires & lieu/)
    click_button("Créer RDV")

    expect(user.rdvs.count).to eq(1)
    rdv = user.rdvs.first
    expect(rdv.users).to contain_exactly(user)
    expect(rdv.motif).to eq(motif)
    expect(rdv.duration_in_min).to eq(motif.default_duration_in_min)
    expect(rdv.created_by_agent?).to be(true)

    expect(page).to have_current_path(admin_organisation_agent_agenda_path(organisation, agent, date: rdv.starts_at.to_date, selected_event_id: rdv.id))
    expect(page).to have_content("Le rendez-vous a été créé.")
    expect(page).to have_content("Votre agenda")
  end
end
