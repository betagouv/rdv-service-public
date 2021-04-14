describe "Agent can CRUD absences" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

  before do
    login_as(agent, scope: :agent)
    visit authenticated_agent_root_path
  end

  context "for an agent" do
    let!(:absence) { create(:absence, agent: agent, organisation: organisation) }

    it "can crud a absence" do
      click_link "Absences"

      expect_page_title("Vos absences")
      click_link absence.title

      expect_page_title("Modifier votre absence")
      fill_in "Description", with: "La belle absence"
      click_button("Enregistrer")

      expect_page_title("Vos absences")
      click_link "La belle absence"

      click_link("Supprimer")
      expect_page_title("Vos absences")
      expect(page).to have_content("Vous n'avez pas encore créé d'absence")

      click_link "Créer une absence", match: :first

      expect_page_title("Nouvelle absence")
      fill_in "Description", with: "Nouvelle Absence"
      fill_in "absence[first_day]", with: Time.zone.today
      fill_in "absence[end_day]", with: Time.zone.today + 2
      click_button "Enregistrer"

      expect_page_title("Vos absences")
      click_link "Nouvelle Absence"
    end
  end

  context "for an other agent calendar" do
    let!(:service) { create(:service, name: "PMI") }
    let!(:other_agent) { create(:agent, first_name: "Jane", last_name: "FAROU", service: service, basic_role_in_organisations: [organisation]) }
    let!(:absence) { create(:absence, agent: other_agent, organisation: organisation) }

    it "can crud a absence" do
      visit admin_organisation_agent_absences_path(organisation, other_agent.id)
      expect_page_title("Absences de Jane FAROU (PMI)")
      click_link absence.title

      expect_page_title("Modifier l'absence de Jane FAROU")
      fill_in "Description", with: "La belle absence"
      click_button("Enregistrer")

      expect_page_title("Absences de Jane FAROU (PMI)")
      click_link "La belle absence"

      click_link("Supprimer")
      expect_page_title("Absences de Jane FAROU (PMI)")
      expect(page).to have_content("Jane FAROU n'a pas encore créé d'absence")

      click_link "Créer une absence", match: :first

      expect_page_title("Nouvelle absence")
      fill_in "Description", with: "Nouvelle Absence"
      fill_in "absence[first_day]", with: Time.zone.today
      fill_in "absence[end_day]", with: Time.zone.today + 2
      click_button "Enregistrer"

      expect_page_title("Absences de Jane FAROU (PMI)")
      click_link "Nouvelle Absence"
    end
  end

  context "view past absences" do
    let!(:future_absence) { create(:absence, agent: agent, organisation: organisation) }
    let!(:past_absence) { create(:absence, :past, agent: agent, organisation: organisation) }

    it do
      click_link "Absences"
      expect_page_title("Vos absences")

      click_link "En cours"
      expect(page).to have_content(future_absence.title)
      expect(page).not_to have_content(past_absence.title)

      click_link "Passées"
      expect(page).to have_content(past_absence.title)
      expect(page).not_to have_content(future_absence.title)
    end
  end
end
