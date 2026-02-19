RSpec.describe "Prise de RDV pour un proche" do
  def check_or_click_submit(text)
    if Capybara.current_driver == Capybara.javascript_driver
      check(text, allow_label_click: true)
    else
      click_button(text)
    end
  end

  before do
    travel_to(Time.zone.parse("2021-12-13 8:00"))
    stub_netsize_ok
    login_as(user, scope: :user)
  end

  let!(:territory) { create(:territory, departement_number: "92") }
  let!(:organisation) { create(:organisation, :with_contact, territory:) }
  let!(:motif) { create(:motif, organisation:) }
  let!(:lieu) { create(:lieu, organisation:) }
  let!(:plage_ouverture) do
    create(
      :plage_ouverture, :weekdays,
      first_day: Date.parse("2022-01-13"), motifs: [motif], lieu:, organisation:,
      start_time: Tod::TimeOfDay.new(11), end_time: Tod::TimeOfDay.new(12)
    )
  end
  let!(:user) { create(:user, organisations: [organisation]) }

  let(:wizard_path) do
    new_users_rdv_wizard_step_path(
      motif_id: motif.id, lieu_id: lieu.id, departement: "92",
      starts_at: Time.zone.parse("2022-01-13 11:00")
    )
  end

  context "sélection d'un proche existant" do
    let!(:proche) { create(:user, first_name: "Marie", last_name: "Martin", responsible: user) }

    it "crée le RDV avec le proche sélectionné" do
      visit wizard_path
      check_or_click_submit("Je prends rendez-vous pour un·e proche")
      choose(proche.full_name, allow_label_click: true)
      click_button("Confirmer mon RDV")
      expect(page).to have_content("Votre RDV")
      expect(Rdv.last.users).to include(proche)
    end
  end

  context "création d'un nouveau proche" do
    it "crée le RDV avec le nouveau proche" do
      visit wizard_path
      check_or_click_submit("Je prends rendez-vous pour un·e proche")
      within(".fr-fieldset__element", text: "Informations du proche") do
        fill_in("Prénom", with: "Mathieu")
        fill_in("Nom", with: "Lapin")
      end
      click_button("Confirmer mon RDV")
      expect(page).to have_content("Votre RDV")
      expect(Rdv.last.users).to include(User.find_by(first_name: "Mathieu", last_name: "Lapin"))
    end
  end

  context "sur le domaine RDV Service Public" do
    it "n'affiche pas le champ 'Nom de naissance'", js: true do
      visit "http://www.rdv-service-public-test.localhost#{wizard_path}"
      expect(page).not_to have_field("Nom de naissance")
      check_or_click_submit("Je prends rendez-vous pour un·e proche")
      within(".fr-fieldset__element", text: "Informations du proche") do
        fill_in("Prénom", with: "Mathieu")
        fill_in("Nom", with: "Lapin")
      end
      click_button("Confirmer mon RDV")
      expect(page).to have_content("Votre RDV")
    end
  end
end
