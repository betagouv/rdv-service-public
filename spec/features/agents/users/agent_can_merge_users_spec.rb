RSpec.describe "Agent can delete user" do
  let!(:organisation) { create(:organisation, territory: territory) }
  let!(:territory) { create(:territory, enable_logement_field: true, enable_notes_field: true) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:user1) do
    create(
      :user,
      email: "aalyah@damn.com",
      first_name: "Aalyah",
      last_name: "SWAN",
      birth_date: nil,
      phone_number: "01 02 03 04 05",
      logement: "locataire"
    )
  end
  let!(:user_profile1) do
    create(:user_profile, user: user1, organisation: organisation)
  end
  let!(:user2) do
    create(
      :user,
      email: nil,
      first_name: "Anna",
      last_name: "SWAN",
      birth_date: nil,
      phone_number: "01 09 09 09 09",
      organisations: [organisation],
      logement: "proprietaire"
    )
  end

  it "normal", js: true do
    login_as(agent, scope: :agent)
    visit authenticated_agent_root_path
    click_link "Usagers"
    click_link "Fusionner deux usagers"

    find("#select2-user1_id-container").click
    find(".select2-search__field").send_keys("SWA")
    find(".select2-results__option") { _1.text == "SWAN Aalyah" }.click

    find("#select2-user2_id-container").click
    find(".select2-search__field").send_keys("SWA")
    find(".select2-results__option") { _1.text == "SWAN Anna" }.click
    choose "aalyah@damn.com"
    choose "Anna"

    find("label", text: "Locataire").click

    # forget to check phone number
    find("input[type=submit]").click
    page.driver.browser.switch_to.alert.accept
    message = page.find("#merge_users_form_phone_number_1").native.attribute("validationMessage") # cf https://stackoverflow.com/a/48206413
    expect(message).to eq("Please select one of these options.").or(eq("Veuillez sélectionner l'une de ces options."))

    choose "01 02 03 04 05"
    find("input[type=submit]").click
    page.driver.browser.switch_to.alert.accept

    expect_page_title("Anna SWAN")
    expect(page).to have_content("Les usagers ont été fusionnés")
    expect(page).to have_content("aalyah@damn.com")
  end

  it "displays all fields" do
    Annotation.create!(user: user1, territory: territory, content: "Notes 1")
    Annotation.create!(user: user2, territory: territory, content: "Notes 2")

    login_as(agent, scope: :agent)
    visit new_admin_organisation_merge_users_path(organisation_id: organisation.id, user1_id: user1.id, user2_id: user2.id)
    expect(page).to have_content("Notes 1")
    expect(page).to have_content("Notes 2")
    choose "Notes 2"
    click_on "Fusionner"
    expect(user1.reload.annotations.sole.content).to eq("Notes 2")
    expect(user2.reload.deleted_at).to be_present
    expect(user2.reload.annotations).to be_empty
  end
end
