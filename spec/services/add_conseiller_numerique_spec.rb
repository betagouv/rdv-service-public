RSpec.describe AddConseillerNumerique do
  let!(:territory) { create(:territory, name: "Conseillers Numériques") }
  let(:params) do
    {
      external_id: "exemple@conseiller-numerique.fr",
      email: "exemple@conseiller-numerique.fr",
      secondary_email: "mail_perso@gemelle.com",
      first_name: "Camille",
      last_name: "Clavier",
      structure: {
        external_id: "123456",
        name: "France Service 19e",
        address: "16 quai de la Loire, Paris, 75019",
      },
    }
  end

  before do
    create(:service, :conseiller_numerique)
    stub_request(
      :get,
      "https://api-adresse.data.gouv.fr/search/?postcode=75019&q=16%20quai%20de%20la%20Loire,%20Paris,%2075019"
    ).to_return(status: 200, body: file_fixture("geocode_result.json").read, headers: {})
  end

  context "when the conseiller numerique and their structure have never been imported before" do
    it "creates the agent for the conseiller numerique and notifies them" do
      described_class.process!(params)
      expect(Agent.count).to eq 1
      expect(Agent.last).to have_attributes(
        external_id: "exemple@conseiller-numerique.fr",
        email: "exemple@conseiller-numerique.fr",
        cnfs_secondary_email: "mail_perso@gemelle.com",
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

      perform_enqueued_jobs
      invitation_email = ActionMailer::Base.deliveries.last

      expect(invitation_email).to have_attributes(to: ["exemple@conseiller-numerique.fr"], from: ["support@rdv-aide-numerique.fr"])
    end
  end

  describe "special cases for the agent" do
    context "when the conseiller numerique has already been imported" do
      context "and they still exists with the same email" do
        before { create(:agent, external_id: "exemple@conseiller-numerique.fr") }

        it "does nothing" do
          expect { described_class.process!(params) }.not_to change { [Agent.count, Agent.maximum(:updated_at)] }
        end
      end

      context "and their account has been deleted by mistake before the external id was set" do
        before { create(:agent, external_id: nil, deleted_at: 1.day.ago) }

        it "creates a new agent, and assigns them to the organisation" do
          described_class.process!(params)
          expect(Agent.count).to eq 2
          expect(Agent.last).to have_attributes(
            external_id: "exemple@conseiller-numerique.fr",
            email: "exemple@conseiller-numerique.fr",
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
        let!(:agent) { create(:agent, external_id: "exemple@conseiller-numerique.fr", admin_role_in_organisations: [old_organisation]) }

        it "adds the agent to the new org" do
          expect(agent.organisations).to eq([old_organisation])
          described_class.process!(params)
          expect(agent.organisations.reload).to match_array([old_organisation, Organisation.find_by(external_id: "123456")])
        end
      end
    end
  end

  describe "special cases for organisations" do
    context "when there is already an organisation with this external id" do
      before { create(:organisation, external_id: "123456", territory: Territory.find_by!(name: "Conseillers Numériques")) }

      it "does nothing" do
        expect { described_class.process!(params) }.not_to change(Organisation, :count)
      end
    end
  end
end

render(
  action =>
    filtered(
      (
        policy_scope(
          current_organisation.motifs,
          :policy_scope_class => Agent::MotifPolicy::Scope
        ).active.search_by_text(params[:search]) or policy_scope(current_organisation.motifs, :policy_scope_class => Agent::MotifPolicy::Scope)
                                                                                                          .active.ordered_by_name
      ), params
    ).includes(:organisations).includes(:service).page(params[:page])
)
