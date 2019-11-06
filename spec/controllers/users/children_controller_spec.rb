RSpec.describe Users::ChildrenController, type: :controller do
  render_views

  let(:user) { create(:user) }
  let!(:child) { create(:user, first_name: "Katia", last_name: "Garcia", birth_date: Date.parse("12/10/1990"), parent_id: user.id) }

  before do
    travel_to(Time.zone.local(2019, 7, 20))
    sign_in user
  end

  after { travel_back }

  describe "GET #edit" do
    subject { get :edit, params: { id: child.id } }

    before { subject }

    it "returns a success response" do
      expect(response).to be_successful
    end

    it "should assign child" do
      expect(response.body).to include("Modifier un enfant")
      expect(assigns(:user)).to eq(child)
    end
  end

  describe "GET #new" do
    subject { get :new }

    before { subject }

    it "returns a success response" do
      expect(response).to be_successful
    end

    it "should assign a new user" do
      expect(response.body).to include("Ajouter un enfant")
      expect(assigns(:user)).to be_a_new(User)
    end
  end

  describe "POST #create" do
    subject { post :create, params: attributes }

    context "with valid params" do
      let(:attributes) do
        { user: { first_name: "Eliott", last_name: "Le Dragon" } }
      end

      it "creates a new User" do
        expect do
          subject
        end.to change(User, :count).by(1)
      end

      it "redirects to user informations" do
        subject
        expect(response).to redirect_to(users_informations_path)
      end
    end

    context "with invalid params" do
      let(:attributes) do
        { user: { first_name: "Eliott" } }
      end

      it "does not creates a new User" do
        expect do
          subject
        end.not_to change(User, :count)
      end

      it "returns a success response (i.e. to display the 'new' template)" do
        subject
        expect(response).to be_successful
        expect(response).to render_template(:new)
      end
    end
  end

  describe "POST #update" do
    subject do
      post :update, params: attributes
      child.reload
    end

    context "with valid params" do
      let(:attributes) do
        { id: child.id, user: { first_name: "Eliott" } }
      end

      it "creates a new User" do
        expect do
          subject
        end.to change(child, :first_name).from("Katia").to("Eliott")
      end

      it "redirects to user informations" do
        subject
        expect(response).to redirect_to(users_informations_path)
      end
    end

    context "with invalid params" do
      let(:attributes) do
        { id: child.id, user: { first_name: " " } }
      end

      it "does not creates a new User" do
        expect do
          subject
        end.not_to change(child, :first_name)
      end

      it "returns a success response (i.e. to display the 'edit' template)" do
        subject
        expect(response).to be_successful
        expect(response).to render_template(:edit)
      end
    end
  end
end
