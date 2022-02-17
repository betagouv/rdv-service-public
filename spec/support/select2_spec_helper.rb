# frozen_string_literal: true

module Select2SpecHelper
  def select_user(user)
    find(".collapse-add-user-selection .select2-selection").click
    find(".select2-search__field").send_keys(user.last_name[0..2])
    find(".select2-results li.select2-results__option", text: user.reverse_full_name).click
    expect(page).to have_selector("a[title='Modifier']")
  end

  def add_user(user)
    find("span", text: "Ajouter un usager", match: :first).click
    sleep 0.5
    find("li", text: user.last_name).click
    sleep 0.5
  end
end
