RSpec.describe "Un agent peut réinitialiser son mot de passe" do
  let!(:agent) { create(:agent) }

  it "envoie un email de réinitialisation" do
    visit new_agent_password_path
    expect(page).to have_content("Mot de passe oublié ?")
    expect(page).to have_link("Se connecter")

    fill_in "agent_email", with: agent.email
    perform_enqueued_jobs do
      expect { click_on "Envoyer" }.to change { emails_sent_to(agent.email).size }.by(1)
    end

    open_email(agent.email)
    current_email.click_link("Changer")
    expect(page).to have_content("Définir mon mot de passe")

    fill_in "Mot de passe", with: "q1w2e3r4t5y6"
    expect { click_on "Enregistrer" }.not_to change { agent.reload.encrypted_password }
    expect(page).to have_content("Ce mot de passe fait partie d'une liste de mots de passe fréquemment utilisés")

    fill_in "Mot de passe", with: "correct H0rse battery! staple"
    expect { click_on "Enregistrer" }.to change { agent.reload.encrypted_password }
    expect(page).to have_content("Votre mot de passe a été édité avec succès")
  end

  context "quand l’agent à un sub ProConnect" do
    let!(:pro_connect_agent) { create(:agent, pro_connect_openid_sub: "some-sub") }

    it "n’envoie pas le mail de réinitialisation depuis le formulaire agent" do
      visit new_agent_password_path
      fill_in "agent_email", with: pro_connect_agent.email
      perform_enqueued_jobs do
        expect { click_on "Envoyer" }.not_to change { emails_sent_to(pro_connect_agent.email).size }
      end
      expected_message = "Si un compte agent existe pour #{pro_connect_agent.email} et que ce compte n’est pas associé à " \
                         "un compte ProConnect, alors un email de réinitialisation va y être envoyé avec un lien de réinitialisation de mot de passe"
      expect(page).to have_content(expected_message)
    end
  end

  context "quand l’email n’existe pas" do
    it "affiche un message générique sans révéler que le compte n'existe pas" do
      visit new_agent_password_path
      fill_in "agent_email", with: "unknown@example.com"

      perform_enqueued_jobs do
        expect { click_on "Envoyer" }.not_to change { ActionMailer::Base.deliveries.size }
      end
      expected_message = "Si un compte agent existe pour unknown@example.com et que ce compte n’est pas associé à " \
                         "un compte ProConnect, alors un email de réinitialisation va y être envoyé avec un lien de réinitialisation de mot de passe"
      expect(page).to have_content(expected_message)
    end
  end

  context "quand l'agent n'a pas encore accepté son invitation" do
    let!(:agent_not_accepted) { create(:agent, :invitation_not_accepted) }

    it "affiche un message générique et renvoie l'invitation" do
      visit new_agent_password_path
      fill_in "agent_email", with: agent_not_accepted.email

      perform_enqueued_jobs do
        expect { click_on "Envoyer" }.to change { emails_sent_to(agent_not_accepted.email).size }.by(1)
      end
      expected_message = "Si un compte agent existe pour #{agent_not_accepted.email} et que ce compte n’est pas associé à " \
                         "un compte ProConnect, alors un email de réinitialisation va y être envoyé avec un lien de réinitialisation de mot de passe"
      expect(page).to have_content(expected_message)
    end
  end

  describe "POST /agents/password", type: :request do
    context "quand le paramètre email est absent" do
      let!(:intervenant) { create(:agent, :intervenant) }

      it "n'envoie pas de reset_password_instructions à un intervenant sans email" do
        expect do
          post agent_password_path, params: { agent: {} }
        end.not_to have_enqueued_mail(CustomDeviseMailer, :reset_password_instructions)
      end
    end
  end
end
