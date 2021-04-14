describe "Agent can update a relative" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:user) do
    create(:user, first_name: "Fiona", last_name: "LEGENDE", email: "jean@legende.com", organisations: [organisation])
  end

  let!(:relative) do
    create(:user, :relative, responsible: user, first_name: "Mimi", last_name: "LEGENDE")
  end

  before do
    login_as(agent, scope: :agent)
    visit authenticated_agent_root_path
    click_link "Usagers"
    click_link "Mimi LEGENDE"
    click_link "Modifier"
  end

  it "works" do
    fill_in :user_first_name, with: "Michelle"
    fill_in :user_last_name, with: "Mythe"
    fill_in :user_birth_date, with: "07/11/2001"
    click_button "Enregistrer"
    expect_page_title "Michelle MYTHE"
    expect(page).to have_content("L'usager a été modifié")
    expect(find("#spec-primary-user-card")).to have_content("Informations de votre proche")
    expect(find("#spec-secondary-user-card")).to have_content("Informations sur l'usager en charge")
  end
end
