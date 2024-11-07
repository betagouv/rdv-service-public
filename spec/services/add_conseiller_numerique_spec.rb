RSpec.describe AddConseillerNumerique do
  let!(:territory) { create(:territory, :conseillers_numeriques) }
  let(:params) do
    {
      agent: {
        external_id: "123456",
        email: "exemple@tierslieuxettransitions.fr",
        first_name: "Camille",
        last_name: "Clavier",
      },
      organisation: {
        external_id: "123456",
        name: "France Service 19e",
      },
      lieux: [
        {
          name: "Bureaux PIX",
          address: "21 rue des Ardennes, Paris, 75019",
        },
        {
          name: "Dinum",
          address: "20 avenue de Ségur, Paris, 75007",
        },
      ],
    }
  end

  before do
    create(:service, :conseiller_numerique)
    stub_request(
      :get,
      "https://api-adresse.data.gouv.fr/search/?postcode=75019&q=21%20rue%20des%20Ardennes,%20Paris,%2075019"
    ).to_return(status: 200, body: file_fixture("geocode_result.json").read, headers: {})
    stub_request(
      :get,
      "https://api-adresse.data.gouv.fr/search/?postcode=75007&q=20%20avenue%20de%20S%C3%A9gur,%20Paris,%2075007"
    ).to_return(status: 200, body: file_fixture("geocode_result.json").read, headers: {})
  end

  context "when the conseiller numerique and their structure have never been imported before" do
    it "creates the agent for the conseiller numerique and notifies them" do
      agent = described_class.process!(**params)
      expect(agent).to have_attributes(
        external_id: "conseiller-numerique-123456",
        email: "exemple@tierslieuxettransitions.fr",
        first_name: "Camille",
        last_name: "Clavier"
      )

      expect(Organisation.last).to have_attributes(
        external_id: "123456",
        name: "France Service 19e"
      )

      expect(Agent.last.roles.last).to have_attributes(
        access_level: "admin",
        organisation_id: Organisation.last.id
      )

      expect(agent.organisations.last.lieux.last).to have_attributes(
        {
          name: "Dinum",
          address: "20 avenue de Ségur, Paris, 75007",
        }
      )

      perform_enqueued_jobs
      invitation_email = ActionMailer::Base.deliveries.last

      expect(invitation_email).to have_attributes(
        to: ["exemple@tierslieuxettransitions.fr"],
        from: ["support@rdv-aide-numerique.fr"]
      )

      # And when trying a second time, it doesn't re-create the agent or the organisation
      expect do
        new_agent = described_class.process!(**params)
        expect(new_agent).to eq(agent)
      end.not_to change {
        [Agent.count, Organisation.count]
      }
    end
  end

  describe "special cases for the agent" do
    context "when the conseiller numerique has already been imported" do
      context "and their account has been deleted by mistake before the external id was set" do
        before { create(:agent, external_id: nil, deleted_at: 1.day.ago) }

        it "creates a new agent, and assigns them to the organisation" do
          described_class.process!(**params)
          expect(Agent.count).to eq 2
          expect(Agent.last).to have_attributes(
            external_id: "conseiller-numerique-123456",
            email: "exemple@tierslieuxettransitions.fr",
            first_name: "Camille",
            last_name: "Clavier"
          )

          expect(Agent.last.roles.count).to eq 1
          expect(Agent.last.agent_territorial_access_rights.first).to have_attributes(
            territory: territory,
            allow_to_manage_teams: false,
            allow_to_manage_access_rights: false,
            allow_to_invite_agents: false
          )
        end
      end

      context "and their organisation's external_id changed" do
        let!(:old_organisation) { create(:organisation, external_id: "019283") } # this ID is not the provided one
        let!(:agent) { create(:agent, external_id: "conseiller-numerique-123456", admin_role_in_organisations: [old_organisation]) }

        it "adds the agent to the new org" do
          expect(agent.organisations).to eq([old_organisation])
          described_class.process!(**params)
          expect(agent.organisations.reload).to contain_exactly(old_organisation, Organisation.find_by(external_id: "123456"))
        end
      end
    end
  end
end
