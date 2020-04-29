module Select2SpecHelper
  def select_user(user)
    find(".select2-selection").click
    find(:xpath, "//body").find(".select2-search input.select2-search__field").set(user.full_name)
    sleep(0.5)
    page.execute_script(%|$("input.select2-search__field:visible").keyup();|)
    find(:xpath, "//body").find(".select2-results li.select2-results__option", text: user.full_name).click
    expect(page).to have_content('Modifier')
  end
end
