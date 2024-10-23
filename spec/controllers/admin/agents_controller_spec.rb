RSpec.describe Admin::AgentsController, type: :controller do
  render_views

  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
  let!(:agent1) { create(:agent, admin_role_in_organisations: [organisation], invitation_sent_at: 3.days.ago, invitation_accepted_at: nil) }
  let!(:organisation2) { create(:organisation) }
  let(:service_id) { agent.services.first.id }

  before do
    request.env["devise.mapping"] = Devise.mappings[:agent]
    sign_in agent
  end

  after { Devise.mailer.deliveries.clear }

  describe "GET #index" do
    describe "HTML version" do
      it "returns a success response" do
        get :index, params: { organisation_id: organisation.id }
        expect(response).to be_successful
      end
    end

    describe "JSON version" do
      it "returns agents as JSON" do
        francis = create(:agent, first_name: "Francis", last_name: "Factice", organisations: [organisation])
        get :index, params: { term: "fra", organisation_id: organisation.id }, format: :json
        expect(response.parsed_body).to eq({ "results" => [{ "id" => francis.id, "text" => "FACTICE Francis" }] })
      end
    end
  end

  describe "DELETE #destroy" do
    subject { delete :destroy, params: { organisation_id: organisation.id, id: agent1.id } }

    it "destroys the requested agent" do
      subject
      expect(agent1.reload.organisations).not_to include(organisation)
    end

    it "redirects to the invitations list" do
      subject
      expect(response).to redirect_to(admin_organisation_invitations_path(organisation))
    end
  end

  describe "GET #new" do
    context "for a cnfs" do
      let!(:agent) do
        create(:agent, admin_role_in_organisations: [organisation],
                       invitation_accepted_at: nil, service: create(:service, :conseiller_numerique))
      end

      before { create(:service, :secretariat) }

      it "only allows inviting agents for the secretariat" do
        get :new, params: { organisation_id: organisation.id }
        expect(response).not_to have_content("Admin")
      end
    end
  end

  describe "POST #create" do
    subject { post :create, params: params }

    shared_examples "existing agent is added to organization" do
      it "adds agent to organisation and redirects to the agents list and does not create a new agent" do
        expect { subject }.not_to change(Agent, :count)
        expect(existing_agent.organisation_ids).to include(organisation.id)
        expect(response).to redirect_to(admin_organisation_agents_path(organisation.id))
      end
    end

    context "when trying to invite while not being an admin" do
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

      let(:params) do
        {
          organisation_id: organisation.id,
          agent: {
            email: "hacker@renard.com",
            service_ids: [service_id],
            agent_role: {
              access_level: "basic",
            },
          },
        }
      end

      it "rejects the change" do
        expect {  subject }.not_to change(AgentRole, :count)
        expect(response.status).to eq 302
        expect(Agent.last.email).not_to eq "hacker@renard.com"
      end
    end

    context "when trying to invite to another organisation" do
      let(:params) do
        {
          organisation_id: organisation2.id,
          agent: {
            email: "hacker@renard.com",
            service_ids: [service_id],
            agent_role: { access_level: "basic" },
          },
        }
      end

      it "rejects the change and redirects" do
        subject
        expect(response.status).to eq 302
        expect(flash[:error]).to eq "Vous n’avez pas les droits suffisants pour accéder à cette organisation"
        expect(Agent.last.email).not_to eq "hacker@renard.com"
      end
    end

    context "when trying to set the role to another organisation" do
      let(:params) do
        {
          organisation_id: organisation.id,
          agent: {
            email: "hacker@renard.com",
            service_ids: [service_id],
            agent_role: { access_level: "basic", organisation_id: organisation2.id },
          },
        }
      end

      it "ignores the organisation param" do
        expect(Agent.last.organisations).to eq [organisation]
      end
    end

    context "when trying to invite an admin as a conseiller numerique" do
      let(:service_id) { create(:service, name: Service::SECRETARIAT).id }
      let(:params) do
        {
          organisation_id: organisation.id,
          agent: {
            email: "michel@lapin.com",
            service_ids: [service_id],
            agent_role: { access_level: "basic" },
          },
        }
      end

      before do
        agent.services.first.update!(name: Service::CONSEILLER_NUMERIQUE)
      end

      it "creates a new basic agent instead of an admin" do
        expect { subject }.to change(Agent, :count).by(1)
        expect(AgentRole.last).to have_attributes(access_level: AgentRole::ACCESS_LEVEL_BASIC)
      end

      context "when the agent already exists" do
        let!(:agent2) do
          create(:agent, basic_role_in_organisations: [organisation2], service: secretariat)
        end
        let(:secretariat) { create(:service, name: Service::SECRETARIAT) }

        let(:params) do
          {
            organisation_id: organisation.id,
            agent: {
              email: agent2.email,
              service_ids: [agent2.services.first.id],
              agent_role: {
                access_level: "basic",
              },
            },
          }
        end

        it "invites the agent" do
          expect { subject }.to change { organisation.agents.count }.by(1)
          expect(AgentRole.last).to have_attributes(access_level: AgentRole::ACCESS_LEVEL_BASIC)
        end
      end
    end

    context "when email is correct and no invitation has been sent" do
      let(:params) do
        {
          organisation_id: organisation.id,
          agent: {
            email: "michel@lapin.com",
            service_ids: [service_id],
            agent_role: { access_level: "basic" },
          },
        }
      end

      it "creates a new agent, sends an email and redirect to invitations list" do
        expect { subject }.to change(Agent, :count).by(1)

        expect(response).to redirect_to(admin_organisation_invitations_path(organisation.id))

        perform_enqueued_jobs
        expect(Devise.mailer.deliveries.count).to eq(1)
      end
    end

    context "when email is incorrect" do
      let(:params) do
        {
          organisation_id: organisation.id,
          agent: {
            email: "aa@hhh",
            service_ids: [service_id],
            agent_role: {
              access_level: "basic",
            },
          },
        }
      end

      it "does not create a new agent and renders the form" do
        expect { subject }.not_to change(Agent, :count)
        expect(response.body).to have_content("Email n'est pas valide")
        expect(response.body).to have_content("Ajouter un agent")
      end
    end

    context "when agent already exist" do
      let(:params) do
        {
          organisation_id: organisation.id,
          agent: {
            email: existing_agent.email,
            service_ids: [service_id],
            agent_role: {
              access_level: "basic",
            },
          },
        }
      end

      context "when agent is in another organisation" do
        let!(:existing_agent) { create(:agent, basic_role_in_organisations: [organisation2], invitation_accepted_at: nil) }

        it_behaves_like "existing agent is added to organization"

        it "does not send an email" do
          subject
          expect(Devise.mailer.deliveries.count).to eq(0)
        end
      end

      context "when agent already exists but has a different service" do
        let(:other_service) { build(:service) }
        let!(:existing_agent) { create(:agent, basic_role_in_organisations: [organisation2], service: other_service, invitation_accepted_at: nil) }

        it_behaves_like "existing agent is added to organization"

        it "displays an error about the mismatch" do
          subject
          expect(flash[:alert]).to match(/Attention : le\(s\) service\(s\) demandé\(s\) .* ne correspondent pas/)
        end
      end

      context "when agent has been invited by another organisation" do
        let!(:existing_agent) do
          create(:agent, :not_confirmed, basic_role_in_organisations: [organisation2], invitation_accepted_at: nil)
        end

        it_behaves_like "existing agent is added to organization"
      end

      context "when agent is already in this organisation" do
        let!(:existing_agent) do
          create(:agent, basic_role_in_organisations: [organisation], invitation_accepted_at: nil)
        end

        it { expect { subject }.not_to change(Agent, :count) }
      end

      context "when agent has been invited by this organisation" do
        let!(:existing_agent) do
          create(:agent, :not_confirmed, basic_role_in_organisations: [organisation], invitation_accepted_at: nil)
        end

        it { expect { subject }.not_to change(Agent, :count) }
      end
    end

    context "when agent already exist but with different email capitalization" do
      let(:params) do
        {
          organisation_id: organisation.id,
          agent: {
            email: "MARCO@demo.rdv-solidarites.fr",
            service_ids: [service_id],
            agent_role: { access_level: "basic" },
          },
        }
      end
      let!(:existing_agent) do
        create(:agent, email: "marco@demo.rdv-solidarites.fr", basic_role_in_organisations: [organisation2], invitation_accepted_at: nil)
      end

      it_behaves_like "existing agent is added to organization"
    end

    describe "initialize access rights for invited agent" do
      it "creates new access rights with none exist" do
        params = { organisation_id: organisation.id,
                   agent: {
                     email: "hacker@renard.com",
                     service_ids: [service_id],
                     agent_role: { access_level: "basic" },
                   }, }
        expect do
          post :create, params: params
        end.to change(AgentTerritorialAccessRight, :count)
      end

      it "do nothing if already exist for this territory" do
        other_organisation_on_same_territory = create(:organisation, territory: organisation.territory)
        existing_agent = create(:agent, organisations: [other_organisation_on_same_territory], email: "hacker@renard.com")
        create(:agent_territorial_access_right, agent: existing_agent, territory: organisation.territory)
        params = { organisation_id: organisation.id,
                   agent: {
                     email: "hacker@renard.com",
                     service_ids: [service_id],
                     agent_role: { access_level: "basic" },
                   }, }
        expect do
          post :create, params: params
        end.not_to change(AgentTerritorialAccessRight, :count)
      end
    end
  end
end
