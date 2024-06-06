RSpec.describe "Agent Connect" do
  let(:agent) { create(:agent, email: "francis.factice@exemple.gouv.fr") }

  it "allows login and logout" do
    # TODO: test account creation as well
    #
    # Cette spec vérifier seulement que le bouton est bien branché à la bonne action de controller.
    # La spec de controller vérifie que notre implémentation de client OpenId est la bonne
    visit "/agents/sign_in"

    begin
      find(".agentconnect-button").click
    rescue ActionController::RoutingError
      # Capybara essaye de suivre une redirection vers l'url d'Agent Connect
      # ce qui n'est pas possible dans l'env de test car il ignore le host et il cherche /authorize dans nos routes.
    end

    expect(page).to have_current_path "/api/v2/authorize"
  end
end
