RSpec.describe "Agent can create a Rdv collectif from the agenda" do
  include UsersHelper

  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, first_name: "Alain", last_name: "Tiptop", email: "alain@tiptop.fr", basic_role_in_organisations: [organisation]) }
  let!(:motif) { create(:motif, :collectif, name: "Atelier administratif", organisation: organisation) }

  let!(:user1) { create(:user, organisations: [organisation]) }
  let!(:user2) { create(:user, organisations: [organisation]) }
  let!(:user3) { create(:user, organisations: [organisation]) }

  let!(:lieu) { create(:lieu, organisation: organisation) }

  before do
    stub_netsize_ok
    login_as(agent, scope: :agent)
    # Depuis que les jours fériés sont affichés sur la journée complète dans le calendrier,
    # cela peut nous empêcher de cliquer sur une plage horaire et générer une flaky.
    # On les retire pour ce test
    allow(OffDays).to receive(:to_full_calendar_array).and_return([])
    visit admin_organisation_planning_agenda_path(organisation, agent_id: agent.id, date: Time.zone.today.next_occurring(:monday))
  end

  it "default", js: true do
    # on souhaite faire le parcours en cliquant depuis l’agenda fullcalendar
    # le travel_to est inopérant côté serveur avec les drivers JS
    # fullcalendar fournit des classes qui s’étendent en lignes et en colonnes
    # si on veut cliquer sur un créneau précis ce n’est pas pratique depuis capybara
    # ici on clique sur une ligne entière, ce qui a pour effet de cliquer au milieu
    # et c’est donc le mercredi qui est choisi un peu au hasard
    # en définissant l’offset on arrive à cliquer sur le lundi 😅
    cal_line = find('.fc-timegrid-slot-lane[data-time="08:30:00"]')
    cal_line_width = cal_line.evaluate_script("this.clientWidth")
    cal_line.click(x: -((cal_line_width / 2)) + 10, y: 0)

    select("Atelier administratif", from: "rdv_motif_id")
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
    perform_enqueued_jobs
    open_email("alain@tiptop.fr")
    expect(current_email.subject).to include("Nouveau RDV ajouté sur votre agenda RDV Service Public")

    rdv = Rdv.last
    expect(rdv.users.count).to eq(0)
    expect(rdv.motif).to eq(motif)
    expect(rdv).to be_collectif

    # Adding participants
    visit admin_organisation_rdv_path(organisation, rdv)
    click_on("Ajouter un participant")

    add_user(user1)
    add_user(user2)
    add_user(user3)
    click_button("Enregistrer")
    expect(page).to have_content("Participants mis à jour")
    expect(rdv.reload.users.count).to eq 3
  end
end
