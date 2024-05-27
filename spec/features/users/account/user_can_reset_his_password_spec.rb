RSpec.describe "User resets his password spec" do
  let!(:user) { create(:user) }

  around { |example| perform_enqueued_jobs { example.run } }

  it "works by sending a reset email" do
    visit new_user_password_path
    expect(page).to have_content("Mot de passe oublié ?")
    expect(page).to have_link("Se connecter")

    fill_in "user_email", with: user.email
    expect { click_on "Envoyer" }.to change { emails_sent_to(user.email).size }.by(1)

    open_email(user.email)
    current_email.click_link("Changer")
    expect(page).to have_content("Définir mon mot de passe")

    fill_in "password", with: "q1w2e3r4t5y6"
    expect { click_on "Enregistrer" }.not_to change { user.reload.encrypted_password }
    expect(page).to have_content("Ce mot de passe fait partie d'une liste de mots de passe fréquemment utilisés")

    fill_in "password", with: "pasassezfort"
    expect { click_on "Enregistrer" }.not_to change { user.reload.encrypted_password }
    expect(page).to have_content("Votre mot de passe doit comporter au moins un chiffre.")

    fill_in "password", with: "Corr3ctHorse,"

    expect { click_on "Enregistrer" }.to change { user.reload.encrypted_password }
    expect(page).to have_content("Votre mot de passe a été édité avec succès")
    expect(page).to have_current_path("/users/rdvs")
  end

  # Ce test constitue un test d'intégration du cas normal.
  # Les tests unitaires des variations sont fait dans une spec de CustomDeviseMailer.
  describe "using the user's domain" do
    context "when the most recent RDV is in an organisation with verticale rdv_aide_numerique" do
      let!(:user) { create(:user) }
      let(:organisation) { create(:organisation, verticale: :rdv_aide_numerique) }
      let!(:rdvs) { create_list(:rdv, 2, organisation: organisation, users: [user]) }

      it "uses the rdv-aide-numerique domain" do
        # Le domaine visité n'a pas d'importance. Voir la doc de User#domain.
        visit new_user_password_url(host: Domain::RDV_SOLIDARITES.host_name)
        fill_in "user_email", with: user.email
        click_on "Envoyer"
        open_email(user.email)
        expect(current_email.base.email[:from].to_s).to eq(%("RDV Aide Numérique" <support@rdv-aide-numerique.fr>))
        expect(current_email.html_part.body.to_s).to include('<a href="http://www.rdv-aide-numerique-test.localhost/users/password/edit?reset_password_token=')
      end
    end
  end
end
