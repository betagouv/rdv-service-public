RSpec.describe "Agents can be managed by organisation admins" do
  let(:territory) { create(:territory) }
  let(:pmi) { create(:service, name: "PMI", territories: [territory]) }
  let(:other_service) { create(:service, territories: []) }
  let(:organisation1) { create(:organisation, territory: territory) }
  let(:organisation2) { create(:organisation, territory: territory) }
  let(:organisation_admin) { create(:agent, service: pmi, admin_role_in_organisations: [organisation1, organisation2]) }

  around { |example| perform_enqueued_jobs { example.run } }

  context "inviting an agent in an existing service" do
    before do
      stub_const("InclusionConnect::IC_CLIENT_ID", "truc")
      stub_const("InclusionConnect::IC_CLIENT_SECRET", "truc secret")
      stub_const("InclusionConnect::IC_BASE_URL", "https://test.inclusion.connect.fr")

      login_as(organisation_admin, scope: :agent)
      visit admin_organisation_agents_path(organisation1)
    end

    it "allows adding an agent in two different organisations" do
      click_link("Ajouter un agent", match: :first)
      fill_in("Email", with: "bob@test.com")
      select(pmi.name, from: "Services")
      click_button("Envoyer une invitation")
      expect(Agent.count).to eq(2)

      visit admin_organisation_agents_path(organisation2)
      click_link("Ajouter un agent", match: :first)
      fill_in("Email", with: "bob@test.com")
      click_button("Envoyer une invitation")
      expect(Agent.count).to eq(2)

      expect(page).to have_content("Invitations en cours")
      expect(organisation2.reload.agents.count).to eq 2
    end

    describe "invitation email domains" do
      context "when the organisation is using rdv_aide_numerique verticale" do
        let!(:organisation1) { create(:organisation, territory: territory, verticale: :rdv_aide_numerique) }

        it "allows inviting agents on the correct domain" do
          click_link "Agents"
          click_link "Ajouter un agent", match: :first
          fill_in "Email", with: "jean@paul.com"
          select(pmi.name, from: "Services")
          click_button "Envoyer une invitation"

          open_email("jean@paul.com")
          expect(current_email.subject).to eq "Vous avez été invité sur RDV Aide Numérique"
          expect(current_email.body).to include "rejoindre RDV Aide Numérique"
        end
      end

      context "when the organisation is using rdv_insertion verticale" do
        let!(:organisation1) { create(:organisation, territory: territory, verticale: :rdv_insertion) }

        it "allows inviting agents on the correct domain" do
          click_link "Agents"
          click_link "Ajouter un agent", match: :first
          fill_in "Email", with: "jean@paul.com"
          select(pmi.name, from: "Services")
          click_button "Envoyer une invitation"

          open_email("jean@paul.com")
          expect(current_email.subject).to eq "Vous avez été invité sur RDV Solidarités"
        end
      end
    end

    specify "CRUD on agents" do
      create(:agent, first_name: "Tony", last_name: "Patrick", email: "tony@patrick.fr", service: pmi, basic_role_in_organisations: [organisation1], invitation_accepted_at: nil)

      click_link "Agents"
      expect_page_title("Agents de Organisation n°1")

      click_link "PATRICK Tony"
      expect_page_title("Modifier le niveau de permission de l'agent Tony PATRICK")
      choose "Administrateur"
      click_button("Enregistrer")

      expect_page_title("Agents de Organisation n°1")
      expect(page).to have_content("Administrateur", count: 2)

      click_link "PATRICK Tony"
      click_link("Supprimer le compte")

      expect_page_title("Agents de Organisation n°1")
      expect(page).to have_no_content("Tony PATRICK")

      click_link "Ajouter un agent", match: :first
      fill_in "Email", with: "jean@paul.com"
      select(pmi.name, from: "Services")
      click_button "Envoyer une invitation"

      expect_page_title("Invitations en cours pour Organisation n°1")
      expect(page).to have_content("jean@paul.com")

      click_on "Se déconnecter"
      open_email("jean@paul.com")
      expect(current_email.subject).to eq "Vous avez été invité sur RDV Solidarités"

      # On évite que l'agent se connecte à InclusionConnect avec
      # une adresse e-mail qui n'est pas celle de l'invitation
      current_email.click_link("Accepter l'invitation")

      begin
        find("a.btn-inclusion-connect").click
      rescue ActionController::RoutingError
        # Capybara essaye de suivre une redirection vers https://test.inclusion.connect.fr/authorize
        # ce qui n'est pas possible dans l'env de test (il ignore le host et il cherche /authorize dans nos routes).
      end

      expect(page.current_url).to start_with("https://test.inclusion.connect.fr/authorize/?")
      redirect_url_query_params = Rack::Utils.parse_query(URI.parse(page.current_url).query)
      expect(redirect_url_query_params["login_hint"]).to eq("jean@paul.com")
    end
  end

  describe "adding an agent to a new service" do
    let(:territory_admin) { create(:agent, service: pmi, role_in_territories: [territory]) }
    let!(:new_service) { create(:service, name: "CSS", territories: []) }

    before do
      create(:agent_territorial_access_right, agent: territory_admin, territory: territory)
    end

    it "requires the territory admin to activate the new service" do
      login_as(organisation_admin, scope: :agent)
      visit new_admin_organisation_agent_path(organisation1)
      expect(page).not_to(have_content("CSS"))
      logout

      login_as(territory_admin, scope: :agent)
      visit admin_territory_path(territory.id)
      click_link("Services")
      check("CSS")
      click_button("Enregistrer")
      expect(page).to have_content("Liste des services disponibles mise à jour")
      logout

      login_as(organisation_admin, scope: :agent)

      visit new_admin_organisation_agent_path(organisation1)
      fill_in "Email", with: "jean@paul.com"
      select("CSS", from: "Services")
      click_button "Envoyer une invitation"

      expect(Agent.last.services.first).to eq(new_service)
    end
  end
end
