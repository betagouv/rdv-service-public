RSpec.describe Agents::PagesController do
  context "quand l'agent est sur le domaine ANCT mais que toutes ses orgas ont la verticale ÉTAT" do
    let(:organisation_etat) { create(:organisation, verticale: :rdv_etat) }
    let(:agent) { create(:agent, basic_role_in_organisations: [organisation_etat]) }

    it "redirige vers le domaine ETAT" do
      sign_in agent
      get authenticated_agent_root_url(host: Domain::RDV_SERVICE_PUBLIC.host_name)
      expect(URI(response.location).host).to eq(Domain::RDV_SERVICE_PUBLIC_ETAT.host_name)
    end
  end

  context "quand l'agent est sur le domaine ANCT et a un panaché d'organisations de verticales ANCT et ÉTAT" do
    let(:organisation_etat) { create(:organisation, verticale: :rdv_etat) }
    let(:organisation_mairie) { create(:organisation, verticale: :rdv_mairie) }
    let(:agent) { create(:agent, basic_role_in_organisations: [organisation_etat, organisation_mairie]) }

    it "ne redirige vers le domaine ETAT" do
      sign_in agent
      get authenticated_agent_root_url(host: Domain::RDV_SERVICE_PUBLIC.host_name)
      expect(URI(response.location).host).to eq(Domain::RDV_SERVICE_PUBLIC.host_name)
    end
  end
end
