RSpec.describe "Un super admin peut chercher un utilisateur", js: true do
  let(:super_admin) { create(:super_admin) }
  let!(:multiple_users) { create_list(:user, 20) } # On remplit la première page pour être sûr que la recherche fonctionne
  let!(:user) { create(:user, first_name: "Francis", last_name: "Factice", email: "francis@test.fr", phone_number: "0612345678") }

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
  end

  context "quand l’usager est FranceConnecté (pas d’email mais un notification_email)" do
    let!(:user) { create(:user, :using_france_connect) }

    it "par notification_email" do
      login_as(super_admin, scope: :super_admin)
      visit super_admins_users_path

      field = find_field("search")
      field.set(user.notification_email)
      page.execute_script <<-JS
        var form = document.querySelector('form');
        form.requestSubmit();
      JS

      expect(page).to have_selector("tr", text: user.first_name)
    end
  end
end
