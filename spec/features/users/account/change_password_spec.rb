RSpec.describe "Changing user password" do
  let(:user) { create(:user, password: "Rdvservicepublictest1!") }

  it "checks password confirmation shows validation errors if the password is too weak, and accepts if it is strong enough" do
    login_as(user, scope: :user)
    visit root_path
    click_link "Votre compte"
    click_link "Changer de mot de passe"

    fill_in "Nouveau mot de passe", with: "tropfaible"
    fill_in "Mot de passe actuel", with: "Rdvservicepublictest1!"

    expect { click_button "Enregistrer" }.not_to change { user.reload.encrypted_password }

    expect(page).to have_content("votre mot de passe doit faire au moins 12 caractères")

    fill_in "Nouveau mot de passe", with: "NouveauRdvservicepublictest1!"
    fill_in "Confirmation du nouveau mot de passe", with: "autre chose"
    fill_in "Mot de passe actuel", with: "Rdvservicepublictest1!"

    expect { click_button "Enregistrer" }.not_to change { user.reload.encrypted_password }

    expect(page).to have_content("Le nouveau mot de passe et la confirmation ne concordent pas")

    fill_in "Nouveau mot de passe", with: "NouveauRdvservicepublictest1!"
    fill_in "Confirmation du nouveau mot de passe", with: "autre chose"
    fill_in "Mot de passe actuel", with: "Rdvservicepublictest1!"

    expect { click_button "Enregistrer" }.to change { user.reload.encrypted_password }
  end
end
