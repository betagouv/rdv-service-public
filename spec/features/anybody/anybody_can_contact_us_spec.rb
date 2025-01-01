RSpec.describe "Tout le monde peut nous contacter" do
  context "un usager nous contacte car il n’arrive pas à annuler son RDV", js: true do
    it "créé un ticket Zammad" do
      visit "/"
      click_on "Contact"

      # étape d’aiguillage basée sur le rôle
      expect(page).to have_content("Vous êtes…")
      find(:label, text: /Vous êtes usager/).click # on ne peut pas utiliser choose car le radio input est caché par le CSS du DSFR
      click_on "Valider"

      expect(page).to have_content("Aide pour les usagers")
      click_on("Comment annuler votre RDV ?")
      expect(page).to have_content("Si le rendez-vous a lieu dans moins de 4 heures, vous ne pouvez plus annuler le RDV")
      click_on "Contacter l’équipe de RDV Service Public"

      expect(page).to have_content("Veuillez sélectionner la raison qui correspond le mieux à votre situation")
      find(:label, text: /Vous ne trouvez pas de créneaux disponibles/).click
      click_on "Valider cette raison"

      expect(page).to have_content("L’équipe de RDV Service Public ne peut pas débloquer de nouvelles disponibilités dans les administrations")
      click_on "Modifier cette raison"

      find(:label, text: /Vous n’arrivez pas à annuler votre RDV/).click
      click_on "Valider cette raison"

      expect(page).to have_content("Avez-vous consulté ces informations qui peuvent vous guider pour annuler votre RDV ?")
      click_on "Contacter l’équipe de RDV Service Public"

      fill_in "Votre prénom", with: "Tamara"
      fill_in "Votre email", with: "tamara.saadi@provider.fr"
      fill_in "Votre message", with: "Je suis tout à fait perdue !"
      click_on "Envoyer votre demande" # on clique avant d’avoir rempli le nom de famille
      sleep(0.5)
      expect(page).to have_content("Formulaire de contact") # on devrait toujours être sur la même page
      fill_in "Votre nom de famille", with: "Saadi"
      stub = stub_request(:post, "https://zammad10.ethibox.fr/api/v1/tickets").to_return(
        body: %({"id": 123, "number": 456, "customer_id": 789, "title": "Contact usager"}),
        headers: { content_type: "application/json" }
      )
      click_on "Envoyer votre demande" # on clique avant d’avoir rempli le nom de famille
      expect(stub).to have_been_requested
    end
  end
end
