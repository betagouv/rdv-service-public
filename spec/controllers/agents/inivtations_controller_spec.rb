RSpec.describe Agents::InvitationsController, type: :controller do
  render_views

  let!(:agent) { create(:agent, :admin) }
  let(:organisation_id) { agent.organisation_ids.first }
  let!(:organisation_2) { create(:organisation) }
  let(:service_id) { agent.service.id }

  before do
    request.env["devise.mapping"] = Devise.mappings[:agent]
    sign_in agent
  end

  after(:each) do
    Devise.mailer.deliveries.clear
  end

  describe "POST #create" do
    subject { post :create, params: { agent: params }, format: :json }

    shared_examples "invitation sent to existing user" do
      it "should not create a new user" do
        expect { subject }.not_to change(Agent, :count)
      end

      it "should return a successful response" do
        subject
        expect(response).to be_successful
      end

      it "should add user to organisation" do
        subject
        expect(assigns(:agent).organisation_ids).to include(organisation_id)
      end
    end

    context "when email is correct and no invitation has been sent" do
      let(:params) do
        {
          email: "michel@lapin.com",
          organisation_id: organisation_id,
          role: 'user',
          service_id: service_id,
        }
      end

      it "should reate a new user" do
        expect { subject }.to change(Agent, :count).by(1)
      end

      it "should return a successful response" do
        subject
        expect(response).to be_successful
      end

      it "should send an email" do
        subject
        expect(Devise.mailer.deliveries.count).to eq(1)
      end
    end

    context "when email is incorrect" do
      let(:params) do
        {
          email: "aa@hhh",
          organisation_id: organisation_id,
          role: 'user',
          service_id: service_id,
        }
      end

      it "should not create a new user" do
        expect { subject }.not_to change(Agent, :count)
      end

      it "should not be successful" do
        subject
        expect(response).not_to be_successful
      end

      it "should render errors" do
        subject
        expect(assigns(:agent).errors[:email]).not_to be_empty
      end
    end

    context "when agent already exist" do
      let(:params) do
        {
          email: agent_2.email,
          organisation_id: organisation_id,
          role: 'user',
          service_id: service_id,
        }
      end

      context "when agent is in another organisation" do
        let!(:agent_2) { create(:agent, organisation_ids: [organisation_2.id]) }

        it_behaves_like "invitation sent to existing user"

        it "should not send an email" do
          subject
          expect(Devise.mailer.deliveries.count).to eq(0)
        end
      end

      context "when agent has been invited by another organisation" do
        let!(:agent_2) { create(:agent, :not_confirmed, organisation_ids: [organisation_2.id]) }

        it_behaves_like "invitation sent to existing user"
      end

      context "when agent is already in this organisation" do
        let!(:agent_2) { create(:agent, organisation_ids: [organisation_id]) }

        it_behaves_like "invitation sent to existing user"

        it "should not send an email" do
          subject
          expect(Devise.mailer.deliveries.count).to eq(0)
        end
      end

      context "when agent has been invited by this organisation" do
        let!(:agent_2) { create(:agent, :not_confirmed, organisation_ids: [organisation_id]) }

        it_behaves_like "invitation sent to existing user"
      end
    end
  end
end
