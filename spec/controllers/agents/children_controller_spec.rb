RSpec.describe Agents::ChildrenController, type: :controller do
  render_views

  let(:agent) { create(:agent, :admin) }
  let(:organisation_id) { agent.organisation_ids.first }
  let!(:parent) { create(:user) }

  before do
    sign_in agent
  end

  describe "GET #new" do
    it "returns a success response" do
      get :new, params: { organisation_id: organisation_id, user_id: parent.id }
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    subject { post :create, params: { organisation_id: organisation_id, user_id: parent.id, user: attributes } }

    context "with valid params" do
      let(:attributes) do
        build(:user).attributes
      end

      it "creates a child for parent" do
        expect do
          subject
        end.to change(parent.children, :count).from(0).to(1)
      end

      it "redirects to the parent edit page" do
        subject
        expect(response).to redirect_to(edit_organisation_user_path(organisation_id, parent.id))
      end
    end

    context "with invalid params" do
      let(:attributes) do
        {
          name: "test",
        }
      end

      it "does not create a new Lieu" do
        expect do
          subject
        end.not_to change(Lieu, :count)
      end

      it "returns a success response (i.e. to display the 'new' template)" do
        subject
        expect(response).to be_successful
      end
    end
  end
end
