RSpec.describe "Tout le monde peut nous contacter" do
  context "un usager nous contacte car il n’arrive pas à annuler son RDV" do
    it "créé un ticket Zammad" do
      visit "/"
      click_on "Contact"

      # étape d’aiguillage basée sur le rôle
      expect(page).to have_content("Vous êtes…")
      find(:label, text: /Vous êtes un·e particulier·ère/).click # on ne peut pas utiliser choose car le radio input est caché par le CSS du DSFR
      click_on "Valider"

      expect(page).to have_content("Veuillez sélectionner la raison qui correspond le mieux à votre situation")
      find(:label, text: /Vous souhaitez prendre un RDV/).click
      click_on "Valider"

      expect(page).to have_content("Sélectionnez un service puis un motif")
      click_on "modifier"

      find(:label, text: /Vous souhaitez annuler votre RDV/).click
      click_on "Valider"

      expect(page).to have_content("Comment annuler votre RDV ?")
      click_on "Contacter l’équipe de RDV Service Public"

      fill_in "Votre prénom", with: "Tamara"
      fill_in "Votre email", with: "tamara.dupont@provider.fr"
      fill_in "Votre message", with: "Je suis tout à fait perdue !"
      click_on "Envoyer votre demande" # on clique avant d’avoir rempli le nom de famille
      sleep(0.5)
      expect(page).to have_content("Formulaire de contact") # on devrait toujours être sur la même page
      fill_in "Votre nom de famille", with: "Dupont"
      click_on "Envoyer votre demande"
      expect(page).to have_content("Votre demande de support a bien été envoyée")
      expect(CreateZammadTicketJob).to have_been_enqueued
    end
  end

  context "un agent non connecté nous contacte depuis le formulaire de contact" do
    it "créé un ticket Zammad" do
      visit "/"
      click_on "Contact"

      # étape d’aiguillage basée sur le rôle
      expect(page).to have_content("Vous êtes…")
      find(:label, text: /Vous êtes un·e agent du service public/).click
      click_on "Valider"

      expect(page).to have_content("Formulaire de contact")
      fill_in "La raison de votre message", with: "Connexion"
      fill_in "Votre prénom", with: "Inès"
      fill_in "Votre nom de famille", with: "Erdo"
      fill_in "Votre email", with: "ines.erdo@aude.fr"
      fill_in "Votre message", with: "Je n’arrive plus à me connecter"
      click_on "Envoyer votre demande"
      expect(page).to have_content("Votre demande de support a bien été envoyée")
      expect(CreateZammadTicketJob).to have_been_enqueued
    end
  end
end
