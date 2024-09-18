module Select2SpecHelper
  def select_user(user)
    find(".collapse-add-user-selection .select2-selection").click
    find(".select2-search__field").send_keys(user.last_name[0..2])
    find(".select2-results li.select2-results__option li", text: user.reverse_full_name).click
    expect(page).to have_content(user.reverse_full_name)
  end

  def add_user(user)
    find("span", text: "Ajouter un usager", match: :first).click
    within(".select2-search--dropdown") do
      fill_in(class: "select2-search__field", with: "#{user.last_name} #{user.first_name}")
    end
    find("li", text: "#{user.last_name} #{user.first_name}").click

    # This is to make sure we wait for the user to be added before doing the next action
    expect(page).to have_content("#{user.first_name} #{user.last_name}")
  end

  def add_new_user(options = {})
    click_link("Créer un usager")
    first_name = Faker::Name.first_name
    last_name = Faker::Name.last_name.upcase
    phone_number = Faker::PhoneNumber.cell_phone until Phonelib.parse(phone_number, "FR").valid?

    fill_in("Prénom", with: first_name)
    fill_in("Nom d’usage", with: last_name)
    fill_in("Téléphone", with: phone_number) if options[:with_phone]
    click_button("Créer usager")

    # Wait for the user to be added before doing the next action
    expect(page).to have_content("#{first_name} #{last_name}")
  end
end
