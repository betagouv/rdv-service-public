RSpec.describe "Agent can create a Rdv collectif from the agenda" do
  include UsersHelper

  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let!(:agent) { create(:agent, first_name: "Alain", last_name: "Tiptop", service: service, basic_role_in_organisations: [organisation]) }
  let!(:motif) { create(:motif, :collectif, service: service, organisation: organisation) }

  let!(:user1) { create(:user, organisations: [organisation]) }
  let!(:user2) { create(:user, organisations: [organisation]) }
  let!(:user3) { create(:user, organisations: [organisation]) }

  let!(:lieu) { create(:lieu, organisation: organisation) }

  let(:now) { Time.zone.parse("2024-01-21 13:00") }

  before do
    stub_netsize_ok
    travel_to(now)
    login_as(agent, scope: :agent)
    # Depuis que les jours fériés sont affichés sur la journée complète dans le calendrier,
    # cela peut nous empêcher de cliquer sur une plage horaire et générer une flaky.
    # On les retire pour ce test
    allow(OffDays).to receive(:to_full_calendar_array).and_return([])
    visit admin_organisation_agent_agenda_path(organisation, agent)
  end

  it "default", js: true do
    find('.fc-timegrid-slot-lane[data-time="08:30:00"]').click # Click on the agenda

    select(motif.name, from: "rdv_motif_id")
    click_button("Continuer")

    # Step 2
    # First we don't add any users
    expect(page).to have_selector("h2", text: "Usager")
    click_button("Continuer")

    # Step 3
    expect(page).to have_selector("h2", text: "Agent, horaires & lieu")
    select(lieu.full_name, from: "rdv_lieu_id")
    click_button("Continuer")

    # Step 4
    expect(page).to have_selector("h2", text: "Notifications")
    expect(page).to have_selector(".list-group-item", text: /Motif/)
    expect(page).to have_selector(".list-group-item", text: /Usager/)
    expect(page).to have_selector(".list-group-item", text: /Agent, horaires & lieu/)

    click_button("Confirmer le RDV")
    sleep 1

    rdv = Rdv.last
    expect(rdv.users.count).to eq(0)
    expect(rdv.motif).to eq(motif)
    expect(rdv).to be_collectif

    # Adding participants
    visit admin_organisation_rdv_path(organisation, rdv)
    click_on("Modifier")

    add_user(user1)
    add_user(user2)
    add_user(user3)
    click_button("Enregistrer")
    expect(page).to have_content("Le rendez-vous a été modifié.")
    expect(rdv.reload.users.count).to eq 3
  end
end
