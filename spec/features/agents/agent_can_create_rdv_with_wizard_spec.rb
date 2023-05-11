# frozen_string_literal: true

describe "Agent can create a Rdv with wizard" do
  include UsersHelper

  let(:territory) { create(:territory, enable_context_field: true) }
  let(:organisation) { create(:organisation, territory: territory) }
  let(:service) { create(:service) }
  let!(:agent) { create(:agent, first_name: "Alain", last_name: "DIALO", service: service, basic_role_in_organisations: [organisation]) }
  let!(:agent2) { create(:agent, first_name: "Robert", last_name: "Martin", service: service, basic_role_in_organisations: [organisation]) }
  let!(:motif) { create(:motif, :collectif, :at_public_office, service: service, organisation: organisation, name: "Super Motif") }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let!(:disabled_lieu) { create(:lieu, organisation: organisation, enabled: false) }
  let!(:user) { create(:user, organisations: [organisation]) }

  around { |example| perform_enqueued_jobs { example.run } }

  before do
    stub_netsize_ok
    travel_to(Time.zone.local(2019, 10, 2))
    login_as(agent, scope: :agent)
    visit new_admin_organisation_rdv_wizard_step_path(organisation_id: organisation.id)
  end

  def step1
    expect_page_title("Nouveau RDV pour le 02/10/2019 à 00:00")
    expect(page).to have_selector(".card-title", text: "1. Motif")
    select(motif.name, from: "rdv_motif_id")
    expect(page).to have_select("rdv_motif_id", text: "Super Motif (Sur place - RDV collectif)", exact: true)
    click_button("Continuer")
  end

  def step2
    expect(page).to have_selector(".card-title", text: "2. Usager(s)")
    expect(page).to have_selector(".list-group-item", text: /Motif/)
    select_user(user)
    click_link("Ajouter")
    expect(page).to have_link("Créer un usager")
    click_link("Créer un usager")

    # create user with mail
    fill_in :user_first_name, with: "Jean-Paul"
    fill_in :user_last_name, with: "Orvoir"
    expect(page).to have_selector(".user_email")
    click_button("Créer usager")

    # create user without email
    click_link("Ajouter")
    click_link("Créer un usager")
    fill_in :user_first_name, with: "Jean-Marie"
    fill_in :user_last_name, with: "Lapin"
    click_button("Créer usager")
    sleep(1) # wait for modal to hide completely
    fill_in :rdv_context, with: "RDV très spécial"
    click_button("Continuer")
    expect(page).not_to have_content("Le rendez-vous a été créé")
  end

  def step3(lieu_availability)
    expect(page).to have_selector(".card-title", text: "3. Agent(s), horaires & lieu")
    expect(page).to have_selector(".list-group-item", text: /Motif/)
    expect(page).to have_selector(".list-group-item", text: /Usager\(s\)/)
    expect(page).to have_selector("input#rdv_duration_in_min[value='#{motif.default_duration_in_min}']")

    if lieu_availability == :enabled
      expect(page).to have_select("rdv_lieu_id", with_options: [lieu.full_name])
      expect(page).not_to have_select("rdv_lieu_id", with_options: [disabled_lieu.full_name])
      select(lieu.full_name, from: "rdv_lieu_id")

      click_link("Définir un lieu ponctuel.")
      expect(page).to have_selector("select#rdv_lieu_id:disabled")
      click_link("Choisir un lieu existant.")
      expect(page).to have_selector("select#rdv_lieu_id:enabled")
      expect(page).to have_select("rdv_lieu_id", with_options: [lieu.full_name])
    else
      click_link("Définir un lieu ponctuel.")
      fill_in "Nom", with: "Café de la gare"
      fill_in "Adresse", with: "3 Place de la Gare, Strasbourg, 67000, 67, Bas-Rhin, Grand Est"
      page.execute_script("document.querySelector('input#rdv_lieu_attributes_latitude').value = '48.583844'")
      page.execute_script("document.querySelector('input#rdv_lieu_attributes_longitude').value = 7.735253")
    end

    fill_in "Durée en minutes", with: "35"
    fill_in "Commence à", with: "11/10/2019 14:15"
    select("DIALO Alain", from: "rdv_agent_ids")
    select("MARTIN Robert", from: "rdv_agent_ids")
    click_button("Continuer")
  end

  def step4
    expect(page).to have_selector(".card-title", text: "4. Notifications")
    expect(page).to have_selector(".list-group-item", text: /Motif/)
    expect(page).to have_selector(".list-group-item", text: /Usager\(s\)/)
    expect(page).to have_selector(".list-group-item", text: /Agent\(s\), horaires & lieu/)

    click_button("Créer RDV")
  end

  describe "create a RDV with an existing lieu" do
    it "works", js: true do
      step1
      step2
      step3(:enabled)
      step4

      expect(user.rdvs.count).to eq(1)
      rdv = user.rdvs.first
      expect(rdv.users.count).to eq(3)
      expect(rdv.motif).to eq(motif)
      expect(rdv.duration_in_min).to eq(35)
      expect(rdv.starts_at).to eq(Time.zone.local(2019, 10, 11, 14, 15))
      expect(rdv.created_by_agent?).to be(true)
      expect(rdv.context).to eq("RDV très spécial")

      expect(page).to have_current_path(admin_organisation_agent_agenda_path(organisation, agent, date: rdv.starts_at.to_date, selected_event_id: rdv.id))
      expect(page).to have_content("Le rendez-vous a été créé.")
      expect(page).to have_css("*", text: "14:15", visible: :all)
    end

    describe "sending webhook upon creation" do
      let!(:webhook_endpoint) { create(:webhook_endpoint, organisation: organisation, target_url: "https://example.com") }

      def visit_step4
        query = {
          motif_id: motif.id,
          duration_in_min: 35,
          starts_at: 1.week.since,
          user_ids: [user.id],
          agent_ids: [agent.id],
          context: "RDV très spécial",
          service_id: nil,
          lieu_id: lieu.id,
        }
        visit new_admin_organisation_rdv_wizard_step_path(organisation, step: 4, **query)
      end

      before do
        # Creating a duplicate RDV with same attributes but different user / agent
        create(:rdv, organisation: organisation, users: [create(:user)], agents: [create(:agent)], motif: motif,
                     lieu: lieu, starts_at: Time.zone.parse("2019-10-11 14:15:00"), duration_in_min: 35, skip_webhooks: true)
      end

      # There was a bug that caused the Rdv payload's "users" to
      # be empty, so this regression test was added.
      # Feel free to move it somewhere else if this file becomes too long.
      it "includes the users list in the payload" do
        visit_step4

        stub_request(:post, "https://example.com/")
        click_button("Créer RDV")
        expect(WebMock).to(have_requested(:post, "https://example.com/").with do |req|
          JSON.parse(req.body)["data"]["users"].map { |user| user["id"] } == [user.id]
        end)
      end
    end
  end

  describe "create a RDV with a single_use lieu" do
    it "works", js: true do
      step1
      step2
      step3(:single_use)
      step4

      expect(user.rdvs.count).to eq(1)
      rdv = user.rdvs.first
      expect(rdv.users.count).to eq(3)
      expect(rdv.motif).to eq(motif)
      expect(rdv.lieu.availability).to eq("single_use")
      expect(rdv.duration_in_min).to eq(35)
      expect(rdv.starts_at).to eq(Time.zone.local(2019, 10, 11, 14, 15))
      expect(rdv.created_by_agent?).to be(true)
      expect(rdv.context).to eq("RDV très spécial")

      expect(page).to have_current_path(admin_organisation_agent_agenda_path(organisation, agent, date: rdv.starts_at.to_date, selected_event_id: rdv.id))
      expect(page).to have_content("Le rendez-vous a été créé.")
    end
  end
end
