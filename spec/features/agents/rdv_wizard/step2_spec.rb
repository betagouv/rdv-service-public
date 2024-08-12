RSpec.describe "Step 2 of the rdv wizard" do
  let(:motif) { create(:motif, :by_phone, organisation: organisation) }
  let(:params) do
    {
      organisation_id: organisation.id,
      duration_in_min: 30,
      motif_id: motif.id,
      starts_at: 2.days.from_now,
      step: 2,
    }
  end
  let!(:user) { create(:user, organisations: [organisation], first_name: "François", last_name: "Fictif", phone_number: "06.11.223344", email: nil, birth_date: Date.new(1990, 1, 1)) }
  let!(:user_from_other_organisation) { create(:user, organisations: [other_organisation], first_name: "Francis", last_name: "Factice", phone_number_formatted: nil, email: "francis@factice.cool") }
  let(:territory) { create(:territory) }
  let(:organisation) { create(:organisation, territory: territory) }
  let(:other_organisation) { create(:organisation, territory: territory) }
  let(:agent) { create(:agent, service: motif.service, basic_role_in_organisations: [organisation]) }

  before { create(:agent_territorial_access_right, agent: agent, territory: territory) }

  it "allows searching for users", :js do
    login_as(agent, scope: :agent)
    visit new_admin_organisation_rdv_wizard_step_path(params)

    # Click on the search field
    find(".collapse-add-user-selection .select2-selection").click

    find(".select2-search__field").send_keys("Franc")

    expect(page).to have_content("FICTIF François - 01/01/1990 - 06 11 22 33 44")
    expect(page).to have_content("Usagers des autres organisations")
    expect(page).to have_content("FACTICE Francis")

    find(".select2-search__field").send_keys("o") # Search is "Franco"

    expect(page).to have_content("FICTIF François")
    expect(page).not_to have_content("Usagers des autres organisations")
    expect(page).not_to have_content("FACTICE Francis")

    find(".select2-search__field").send_keys(:backspace)

    find(".select2-search__field").send_keys("i") # Search is "Franci"

    expect(page).not_to have_content("FICTIF François")
    expect(page).to have_content("Usagers des autres organisations")
    expect(page).to have_content("FACTICE Francis")

    find(".select2-search__field").send_keys(:backspace)
    find(".select2-search__field").send_keys("k")

    expect(page).to have_content("Aucun résultat")
  end
end
