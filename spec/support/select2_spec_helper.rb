module Select2SpecHelper
  def select_user(user)
    find(".js-add-user-interface .select2-selection").click
    find(".select2-results li.select2-results__option", text: user.full_name).click
    expect(page).to have_content("Modifier")
  end
end
