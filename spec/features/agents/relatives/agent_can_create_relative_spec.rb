describe "Agent can create a relative" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:user) do
    create(:user, first_name: "Fiona", last_name: "LEGENDE", email: "jean@legende.com", organisations: [organisation])
  end

  before do
    login_as(agent, scope: :agent)
    visit authenticated_agent_root_path
    click_link "Usagers"
    click_link "Fiona LEGENDE"
  end

  it "should work" do
    expect(page).to have_content("Aucun proche")
    click_link "Ajouter un proche"
    fill_in :user_first_name, with: "Loulou"
    fill_in :user_last_name, with: "Legende"
    fill_in :user_birth_date, with: "07/11/2001"
    click_button "Créer usager"
    expect_page_title("Loulou LEGENDE")
    expect(page).to have_content("L'usager a été créé")
    expect(page).not_to have_content("Aucun proche")
  end
end
