describe "Agent can update a relative" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, organisations: [organisation]) }
  let!(:user) do
    create(:user, first_name: "Fiona", last_name: "LEGENDE", email: "jean@legende.com", organisations: [organisation])
  end
  before { user.profile_for(organisation).update!(notes: "tenebres") }
  let!(:relative) do
    create(:user, :relative, responsible: user, first_name: "Mimi", last_name: "LEGENDE")
  end

  before do
    login_as(agent, scope: :agent)
    visit authenticated_agent_root_path
    click_link "Vos usagers"
    click_link "Mimi LEGENDE"
    click_link "Modifier"
  end

  it "should work" do
    fill_in :user_first_name, with: "Michelle"
    fill_in :user_last_name, with: "Mythe"
    fill_in :user_birth_date, with: "07/11/2001"
    fill_in "Notes", with: "fougue ultime"
    click_button "Modifier"
    expect_page_title "Michelle MYTHE"
    expect(page).to have_content("L'usager a été modifié")
    expect(find('#spec-primary-user-card')).to have_content('Informations de votre proche')
    expect(find('#spec-primary-user-card')).to have_content('fougue ultime')
    expect(find('#spec-secondary-user-card')).to have_content("Informations sur l'usager en charge")
    expect(find('#spec-secondary-user-card')).to have_content('tenebres')
  end
end
