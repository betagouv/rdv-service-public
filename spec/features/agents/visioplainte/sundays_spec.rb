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
      # Cette spec dépend de la date utilisée en JS par full calendar, qui est indépendant des stubs ruby.
      # On préfère donc utiliser la vrai date, et s'arranger pour que le rendez-vous soit le prochain dimanche.
      before { travel_back }

      let(:next_sunday_afternoon) do
        Time.zone.now.at_end_of_week.to_date - 1.day + 15.hours
      end

      let!(:rdv) do
        create(:rdv, agents: [superviseur], starts_at: next_sunday_afternoon)
      end

      it "can be displayed on sunday", js: true do
        visit admin_organisation_agent_agenda_path(organisation, superviseur)
        expect(page).to have_content(rdv.users.first.first_name)
      end
    end
  end

  context "for a normal agent" do
    let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
    let(:organisation) { create(:organisation) }
    let!(:motif) { create(:motif, organisation: organisation, service: agent.services.first) }

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
