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

  after(:each) do
    Devise.mailer.deliveries.clear
  end

  describe "POST #create" do
    subject { post :create, params: params }

    shared_examples "existing agent is added to organization" do
      it "should not create a new agent" do
        expect { subject }.not_to change(Agent, :count)
      end

      it "should redirect to the invitations list" do
        subject
        expect(response).to redirect_to(admin_organisation_invitations_path(organisation.id))
      end

      it "should add agent to organisation" do
        subject
        expect(assigns(:agent).organisation_ids).to include(organisation.id)
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
                level: "basic",
                organisation_id: organisation.id
              }
            }
          }
        }
      end

      it "should create a new agent" do
        expect { subject }.to change(Agent, :count).by(1)
      end

      it "should redirect to invitations list" do
        subject
        expect(response).to redirect_to(admin_organisation_invitations_path(organisation.id))
      end

      it "should send an email" do
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
                level: "basic",
                organisation_id: organisation.id
              }
            }
          }
        }
      end

      it "should not create a new agent" do
        expect { subject }.not_to change(Agent, :count)
      end

      it "should render new page" do
        subject
        expect(response).to render_template(:new)
      end

      it "should render errors" do
        subject
        expect(assigns(:agent).errors[:email]).not_to be_empty
      end
    end

    context "when agent already exist" do
      let(:params) do
        {
          organisation_id: organisation.id,
          agent: {
            email: agent2.email,
            service_id: service_id,
            roles_attributes: {
              "0" => {
                level: "basic",
                organisation_id: organisation.id
              }
            }
          }
        }
      end

      context "when agent is in another organisation" do
        let!(:agent2) { create(:agent, basic_role_in_organisations: [organisation2]) }

        it_behaves_like "existing agent is added to organization"

        it "should not send an email" do
          subject
          expect(Devise.mailer.deliveries.count).to eq(0)
        end
      end

      context "when agent has been invited by another organisation" do
        let!(:agent2) { create(:agent, :not_confirmed, basic_role_in_organisations: [organisation2]) }

        it_behaves_like "existing agent is added to organization"
      end

      context "when agent is already in this organisation" do
        let!(:agent2) { create(:agent, basic_role_in_organisations: [organisation]) }
        it { expect { subject }.not_to change(Agent, :count) }
      end

      context "when agent has been invited by this organisation" do
        let!(:agent2) { create(:agent, :not_confirmed, basic_role_in_organisations: [organisation]) }
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
                level: "basic",
                organisation_id: organisation.id
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
