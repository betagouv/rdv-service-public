RSpec.describe Admin::InvitationsDeviseController, type: :controller do
  render_views

  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
  let!(:organisation2) { create(:organisation) }
  let(:service_id) { agent.service.id }

  before do
    request.env["devise.mapping"] = Devise.mappings[:agent]
    sign_in agent
  end

  after do
    Devise.mailer.deliveries.clear
  end

  describe "POST #create" do
    subject { post :create, params: params }

    shared_examples "existing agent is added to organization" do
      it "does not create a new agent" do
        expect { subject }.not_to change(Agent, :count)
      end

      it "redirects to the invitations list" do
        subject
        expect(response).to redirect_to(admin_organisation_invitations_path(organisation.id))
      end

      it "adds agent to organisation" do
        subject
        expect(existing_agent.organisation_ids).to include(organisation.id)
      end
    end

    context "when trying to invite while not being an admin" do
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

      let(:params) do
        {
          organisation_id: organisation.id,
          agent: {
            email: "hacker@renard.com",
            service_id: service_id,
            roles_attributes: {
              "0" => {
                level: "basic"
              }
            }
          }
        }
      end

      it "rejects the change" do
        expect { subject }.to raise_error(Pundit::NotAuthorizedError)
        expect(Agent.last.email).not_to eq "hacker@renard.com"
      end
    end

    context "when trying to invite to another organisation" do
      let(:params) do
        {
          organisation_id: organisation2.id,
          agent: {
            email: "hacker@renard.com",
            service_id: service_id,
            roles_attributes: {
              "0" => {
                level: "basic"
              }
            }
          }
        }
      end

      it "rejects the change" do
        expect { subject }.to raise_error(Pundit::NotAuthorizedError)
        expect(Agent.last.email).not_to eq "hacker@renard.com"
      end
    end

    context "when trying to set the role to another organisation" do
      let(:params) do
        {
          organisation_id: organisation.id,
          agent: {
            email: "hacker@renard.com",
            service_id: service_id,
            roles_attributes: {
              "0" => {
                level: "basic",
                organisation_id: organisation2.id
              }
            }
          }
        }
      end

      it "ignores the organisation param" do
        expect(Agent.last.organisations).to eq [organisation]
      end
    end

    context "when email is correct and no invitation has been sent" do
      let(:params) do
        {
          organisation_id: organisation.id,
          agent: {
            email: "michel@lapin.com",
            service_id: service_id,
            roles_attributes: {
              "0" => {
                level: "basic"
              }
            }
          }
        }
      end

      it "creates a new agent" do
        expect { subject }.to change(Agent, :count).by(1)
      end

      it "redirects to invitations list" do
        subject
        expect(response).to redirect_to(admin_organisation_invitations_path(organisation.id))
      end

      it "sends an email" do
        subject
        expect(Devise.mailer.deliveries.count).to eq(1)
      end
    end

    context "when email is incorrect" do
      let(:params) do
        {
          organisation_id: organisation.id,
          agent: {
            email: "aa@hhh",
            service_id: service_id,
            roles_attributes: {
              "0" => {
                level: "basic"
              }
            }
          }
        }
      end

      it "does not create a new agent" do
        expect { subject }.not_to change(Agent, :count)
      end

      it "renders new page" do
        subject
        expect(response).to redirect_to new_admin_agent_organisation_invitation_path
      end

      it "renders errors" do
        subject
        expect(flash[:error]).to include "Email n'est pas valide"
      end
    end

    context "when agent already exist" do
      let(:params) do
        {
          organisation_id: organisation.id,
          agent: {
            email: existing_agent.email,
            service_id: service_id,
            roles_attributes: {
              "0" => {
                level: "basic"
              }
            }
          }
        }
      end

      context "when agent is in another organisation" do
        let!(:existing_agent) { create(:agent, basic_role_in_organisations: [organisation2]) }

        it_behaves_like "existing agent is added to organization"

        it "does not send an email" do
          subject
          expect(Devise.mailer.deliveries.count).to eq(0)
        end
      end

      context "when agent has been invited by another organisation" do
        let!(:existing_agent) { create(:agent, :not_confirmed, basic_role_in_organisations: [organisation2]) }

        it_behaves_like "existing agent is added to organization"
      end

      context "when agent is already in this organisation" do
        let!(:existing_agent) { create(:agent, basic_role_in_organisations: [organisation]) }

        it { expect { subject }.not_to change(Agent, :count) }
      end

      context "when agent has been invited by this organisation" do
        let!(:existing_agent) { create(:agent, :not_confirmed, basic_role_in_organisations: [organisation]) }

        it { expect { subject }.not_to change(Agent, :count) }
      end
    end

    context "when agent already exist but with different email capitalization" do
      let(:params) do
        {
          organisation_id: organisation.id,
          agent: {
            email: "MARCO@demo.rdv-solidarites.fr",
            service_id: service_id,
            roles_attributes: {
              "0" => {
                level: "basic"
              }
            }
          }
        }
      end
      let!(:existing_agent) { create(:agent, email: "marco@demo.rdv-solidarites.fr", basic_role_in_organisations: [organisation2]) }

      it_behaves_like "existing agent is added to organization"
    end
  end
end
