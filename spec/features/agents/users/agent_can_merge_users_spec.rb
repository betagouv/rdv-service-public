describe "Agent can delete user" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, organisations: [organisation]) }
  let!(:user1) do
    create(
      :user,
      email: "aalyah@damn.com",
      first_name: "Aalyah",
      last_name: "SWAN",
      birth_date: nil,
      phone_number: "01 02 03 04 05",
      organisations: [organisation]
    )
  end
  let!(:user2) do
    create(
      :user,
      email: nil,
      first_name: "Anna",
      last_name: "SWAN",
      birth_date: nil,
      phone_number: "01 09 09 09 09",
      organisations: [organisation]
    )
  end

  scenario "normal", js: true do
    login_as(agent, scope: :agent)
    visit authenticated_agent_root_path
    click_link "Usagers"
    click_link "Fusionner des fiches"
    find("#select2-user1_id-container").click
    find(".select2-results__option") { _1.text == "Aalyah SWAN" }.click
    find("#select2-user2_id-container").click
    find(".select2-results__option") { _1.text == "Anna SWAN" }.click
    choose "aalyah@damn.com"
    choose "Anna"
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
end
