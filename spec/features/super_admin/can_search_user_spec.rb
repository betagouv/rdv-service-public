RSpec.describe "Un super admin peut chercher un utilisateur", js: true do
  let(:super_admin) { create(:super_admin) }
  let!(:user) { create(:user) }
  let!(:another_user) { create(:user) } # On crée un autre utilisateur pour s’assurer que la recherche fonctionne correctement

  it "par email" do
    login_as(super_admin, scope: :super_admin)
    visit super_admins_users_path

    # Il n’y a pas de bouton de recherche, juste un champ de texte. On doit donc simuler l’appuie sur la touche "Entrée" pour lancer la recherche.
    field = find_field("search")
    field.set(user.email)
    page.execute_script <<-JS
      var form = document.querySelector('form');
      form.requestSubmit();
    JS

    expect(page).to have_selector("tr", text: user.first_name)
    expect(page).not_to have_selector("tr", text: another_user.first_name)
  end

  it "par téléphone" do
    login_as(super_admin, scope: :super_admin)
    visit super_admins_users_path

    field = find_field("search")
    field.set(user.phone_number)
    page.execute_script <<-JS
      var form = document.querySelector('form');
      form.requestSubmit();
    JS

    expect(page).to have_selector("tr", text: user.first_name)
    expect(page).not_to have_selector("tr", text: another_user.first_name)
  end
end
