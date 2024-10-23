RSpec.describe Admin::UsersController, type: :controller do
  render_views

  let(:organisation) { create(:organisation) }
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let(:user) { create(:user, organisations: [organisation]) }

  before do
    sign_in agent
  end

  describe "GET search" do
    it "returns users as JSON" do
      travel_to(Time.zone.parse("2024-10-23 16:00"))
      francis = create(:user, first_name: "Francis", last_name: "Factice", birth_date: Date.new(1990, 4, 2), organisations: [organisation])
      get :search, params: { term: "fra", organisation_id: organisation.id }, format: :json
      expect(response.parsed_body).to eq({ "results" => [{ "id" => francis.id, "text" => "FACTICE Francis - 02/04/1990 - 34 ans" }] })
    end
  end

  describe "DELETE destroy" do
    it "removes user from organisation" do
      expect do
        delete :destroy, params: { organisation_id: organisation.id, id: user.id }
        user.reload
      end.to change(user, :organisation_ids).from([organisation.id]).to([])
    end

    it "appaers to destroy user" do
      expect do
        delete :destroy, params: { organisation_id: organisation.id, id: user.id }
      end.to change(User, :count)
    end

    it "not really destroy user" do
      expect do
        delete :destroy, params: { organisation_id: organisation.id, id: user.id }
      end.not_to change { User.unscoped.count }
    end
  end

  describe "POST #create" do
    subject { post :create, params: { organisation_id: organisation.id, user: attributes } }

    context "for user without email" do
      let(:attributes) do
        {
          first_name: "Michel",
          last_name: "Lapin",
          user_profiles_attributes: { "0" => { "organisation_id" => organisation.id.to_s } },
        }
      end

      it { expect { subject }.to change(User, :count).by(1) }

      it "does not send an invite" do
        post :create, params: { organisation_id: organisation.id, user: attributes, invite_on_create: 0 }
        expect(assigns(:user).invitation_sent_at).to be_nil
      end

      it "redirects to the created user" do
        subject
        expect(response).to redirect_to(admin_organisation_user_path(organisation.id, User.last.id))
      end
    end

    context "for user with already existing email" do
      let!(:user) { create(:user) }

      let(:attributes) do
        {
          first_name: "Michel",
          last_name: "Lapin",
          email: user.email,
          user_profiles_attributes: { "0" => { "organisation_id" => organisation.id.to_s } },
        }
      end

      it { expect { subject }.not_to change(User, :count) }
      it { expect(subject).to render_template(:new) }
    end

    context "with invalid params" do
      let(:attributes) do
        {
          first_name: "Michel",
          user_profiles_attributes: { "0" => { "organisation_id" => organisation.id.to_s } },
        }
      end
      let(:format) { :html }

      it { expect { subject }.not_to change(User, :count) }
      it { expect(subject).to render_template(:new) }

      it do
        subject
        expect(assigns(:user_to_compare)).to be_nil
      end

      it "does not send an invite" do
        subject
        expect(assigns(:user).invitation_sent_at).to be_nil
      end

      context "with valid email" do
        let(:attributes) do
          {
            first_name: "Michel",
            last_name: "Lapin",
            email: "michel@lapin.com",
            user_profiles_attributes: { "0" => { "organisation_id" => organisation.id.to_s } },
          }
        end
        let(:format) { format }

        it "sends an invite" do
          expect_any_instance_of(User).to receive(:invite!)
          post :create, params: { organisation_id: organisation.id, user: attributes, invite_on_create: "1" }
        end
      end
    end
  end

  describe "#index" do
    it "return success" do
      get :index, params: { organisation_id: organisation.id }
      expect(response).to be_successful
    end

    it "assigns users" do
      get :index, params: { organisation_id: organisation.id }
      expect(assigns(:users)).to eq([])
    end

    it "return success with with_me_as_referent filter" do
      get :index, params: { organisation_id: organisation.id, with_me_as_referent: 1 }
      expect(response).to be_successful
    end

    it "assigns user where I am referent" do
      user_with_referent = create(:user, referent_agents: [agent], organisations: [organisation])
      create(:user, referent_agents: [], organisations: [organisation])
      get :index, params: { organisation_id: organisation.id, agent_id: agent.id }
      expect(assigns(:users)).to eq([user_with_referent])
    end
  end
end
