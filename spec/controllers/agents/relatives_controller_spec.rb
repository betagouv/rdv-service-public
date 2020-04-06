RSpec.describe Agents::RelativesController, type: :controller do
  render_views

  let(:agent) { create(:agent, :admin) }
  let(:organisation_id) { agent.organisation_ids.first }
  let!(:responsible) { create(:user) }

  before do
    sign_in agent
  end

  describe "GET #new" do
    it "returns a success response" do
      get :new, params: { organisation_id: organisation_id, user_id: responsible.id }
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    subject { post :create, params: { organisation_id: organisation_id, user_id: responsible.id, user: attributes } }

    context "with valid params" do
      let(:attributes) do
        build(:user).attributes
      end

      it "creates a relative for responsible" do
        expect do
          subject
        end.to change(responsible.relatives, :count).from(0).to(1)
      end

      it "redirects to the responsible show page" do
        subject
        expect(response).to redirect_to(organisation_user_path(organisation_id, responsible.id))
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
