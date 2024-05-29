RSpec.describe "Changing user password" do
  let(:user) { create(:user, password: "Rdvservicepublictest1!") }

  it "allows changing email" do
    login_as(user, scope: :user)
    visit root_path
    click_link "Votre compte"
    click_link "Changer d'adresse email"

    fill_in "Email", with: "nouveau@example.com"
    fill_in "Mot de passe actuel", with: "Rdvservicepublictest1!"

    expect { click_button "Enregistrer" }.to change { user.reload.unconfirmed_email }

    expect(page).to have_content("Merci de vérifier vos emails et de cliquer sur le lien de confirmation pour finaliser la validation de votre nouvelle adresse.")
  end
end
