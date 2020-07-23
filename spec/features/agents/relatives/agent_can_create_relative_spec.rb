describe "Agent can create a relative" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, organisations: [organisation]) }
  let!(:user) do
    create(:user, first_name: "Fiona", last_name: "LEGENDE", email: "jean@legende.com", organisations: [organisation])
  end

  before do
    login_as(agent, scope: :agent)
    visit authenticated_agent_root_path
    click_link "Vos usagers"
    click_link "Fiona LEGENDE"
  end

  it "should work" do
    expect(page).to have_content('Aucun proche')
    click_link "Ajouter un proche"
    fill_in :user_first_name, with: "Loulou"
    fill_in :user_last_name, with: "Legende"
    fill_in :user_birth_date, with: "07/11/2001"
    fill_in "Notes", with: "jeune loup"
    click_button "Créer usager"
    expect_page_title("Fiona LEGENDE")
    expect(page).to have_content("Loulou LEGENDE a été ajouté comme proche")
    expect(page).not_to have_content('Aucun proche')
  end
end
