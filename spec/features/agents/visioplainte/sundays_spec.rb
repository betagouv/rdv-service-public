RSpec.describe "Visioplainte agents can work on sunday" do
  context "for a visioplainte agent" do
    before do
      travel_to(Time.zone.local(2024, 11, 24, 15, 0, 0))
      load Rails.root.join("db/seeds/visioplainte.rb")
      login_as(superviseur, scope: :agent)
    end

    let(:superviseur) { Agent.find_by(first_name: "Superviseur") }
    let(:organisation) { superviseur.organisations.first }

    describe "plages d'ouverture" do
      it "can be created on sunday", js: true do
        visit new_admin_organisation_agent_plage_ouverture_path(organisation_id: organisation.id, agent_id: superviseur.id)

        check "Dépôt de plainte par visioconférence"
        check "Répéter"
        check "Dimanche"
        click_button "Créer la plage d'ouverture"
        expect(page).to have_content("Plage d'ouverture créée")

        expect(PlageOuverture.last.recurrence.to_hash[:on]).to eq ["sunday"]
      end
    end

    describe "absences" do
      it "can be created on sunday", js: true do
        visit new_admin_organisation_agent_absence_path(organisation_id: organisation.id, agent_id: superviseur.id)

        fill_in "Description", with: "réunion hebdo"
        check "Répéter"
        check "Dimanche"
        click_button "Enregistrer"
        expect(page).to have_content("L'indisponibilité a été créée")

        expect(Absence.last.recurrence.to_hash[:on]).to eq ["sunday"]
      end
    end

    describe "rdvs" do
      before do
        create(:plage_ouverture,
               organisation: organisation,
               agent: organisation.agents.first,
               motifs: organisation.motifs,
               first_day: Date.tomorrow,
               start_time: Tod::TimeOfDay.new(14),
               end_time: Tod::TimeOfDay.new(18),
               recurrence: Montrose.every(:week, day: [1, 2, 3, 4, 5, 6, 0], interval: 1, starts: Date.tomorrow, on: %i[monday tuesday thursday friday saturday sunday]))
      end

      include_context "Visioplainte Auth"

      it "can be created and displayed on sunday", js: true do
        Faraday.post "#{Capybara.app_host}/api/visioplainte/rdvs", headers: auth_header, params: { starts_at: "2024-11-30T08:00:00+02:00" }

        admin_organisation_agent_agenda_path(organisation_id: organisation.id, agent_id: superviseur.id)
        require "byebug"
        byebug
      end
    end
  end

  context "for a normal agent" do
    let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
    let(:organisation) { create(:organisation) }

    before { login_as(agent, scope: :agent) }

    it "doesn't display these fields", js: true do
      visit new_admin_organisation_agent_plage_ouverture_path(organisation_id: organisation.id, agent_id: agent.id)
      check "Répéter"
      expect(page).not_to have_content "Dimanche"

      visit new_admin_organisation_agent_absence_path(organisation_id: organisation.id, agent_id: agent.id)
      check "Répéter"
      expect(page).not_to have_content "Dimanche"
    end
  end
end
