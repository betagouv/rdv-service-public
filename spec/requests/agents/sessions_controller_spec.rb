RSpec.describe Agents::SessionsController do
  def post_login(agent, host:)
    post agent_session_url(host:), params: { agent: { email: agent.email, password: "Correcth0rse!" } }
  end

  context "quand l'agent se connecte sur le domaine ETAT, mais qu'il est censé être sur le domaine ANCT" do
    let(:territory) { create(:territory, operator: create(:operator)) }
    let(:organisation_etat) { create(:organisation, verticale: :rdv_mairie, territory:) }
    let(:agent) { create(:agent, basic_role_in_organisations: [organisation_etat]) }

    it "redirige vers le domaine ANCT" do
      post_login(agent, host: Domain::RDV_SERVICE_PUBLIC_ETAT.host_name)
      expect(URI(response.location).host).to eq(Domain::RDV_SERVICE_PUBLIC.host_name)
    end

    it "inclut le paramètre de redirection automatique" do
      post_login(agent, host: Domain::RDV_SERVICE_PUBLIC_ETAT.host_name)
      expect(URI(response.location).query).to include("automatic_redirection_from_other_domain=1")
    end

    it "affiche un message flash à l'arrivée sur le domaine ANCT" do
      get unauthenticated_explicit_agent_root_url(host: Domain::RDV_SERVICE_PUBLIC.host_name, automatic_redirection_from_other_domain: "1")
      expect(flash[:notice]).to include("automatiquement redirigé")
    end

    context "quand l'agent avait tenté d'accéder à une page protégée avant la connexion" do
      it "redirige vers ce chemin sur le domaine ÉTAT" do
        get admin_organisations_url(host: Domain::RDV_SERVICE_PUBLIC_ETAT.host_name)
        post_login(agent, host: Domain::RDV_SERVICE_PUBLIC_ETAT.host_name)
        expect(URI(response.location).host).to eq(Domain::RDV_SERVICE_PUBLIC.host_name)
        expect(URI(response.location).path).to eq(admin_organisations_path)
      end
    end
  end

  context "quand l'agent se connecte sur le domaine ETAT et a des organisations de verticales ANCT et ÉTAT" do
    let(:territory) { create(:territory, operator: create(:operator)) }
    let(:organisation_mairie) { create(:organisation, verticale: :rdv_mairie, territory:) }
    let(:organisation_etat) { create(:organisation, verticale: :rdv_mairie) }
    let(:agent) { create(:agent, basic_role_in_organisations: [organisation_etat, organisation_mairie]) }

    it "ne redirige pas vers le domaine ANCT" do
      post_login(agent, host: Domain::RDV_SERVICE_PUBLIC_ETAT.host_name)
      expect(URI(response.location).host).to eq(Domain::RDV_SERVICE_PUBLIC_ETAT.host_name)
    end
  end
end
