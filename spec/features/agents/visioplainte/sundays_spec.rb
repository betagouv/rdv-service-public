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
  end

  context "for a normal agent" do
  end
end
