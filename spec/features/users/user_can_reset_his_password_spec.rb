# frozen_string_literal: true

describe "User resets his password spec" do
  let!(:user) { create(:user) }

  it "works by sending a reset email" do
    visit new_user_password_path
    expect(page).to have_content("Mot de passe oublié ?")
    expect(page).to have_link("Se connecter")

    fill_in "user_email", with: user.email
    expect { click_on "Envoyer" }.to change { emails_sent_to(user.email).size }.by(1)

    open_email(user.email)
    current_email.click_link("Changer")
    expect(page).to have_content("Définir mon mot de passe")
    fill_in "password", with: "correct horse battery staple"
    expect { click_on "Enregistrer" }.to change { user.reload.encrypted_password }
    expect(page).to have_content("Votre mot de passe a été édité avec succès")
    expect(page).to have_current_path("/users/rdvs")
  end
end
