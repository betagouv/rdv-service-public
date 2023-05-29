# frozen_string_literal: true

RSpec.describe Users::RelativesController, type: :controller do
  render_views

  let(:user) { create(:user) }
  let!(:relative) { create(:user, first_name: "Katia", last_name: "Garcia", birth_date: Date.parse("12/10/1990"), responsible_id: user.id) }

  before do
    travel_to(Time.zone.local(2019, 7, 20))
    sign_in user
  end

  describe "GET #edit" do
    subject { get :edit, params: { id: relative.id } }

    before { subject }

    it "returns a success response" do
      expect(response).to be_successful
    end

    it "assigns relative" do
      expect(response.body).to include("Modifier un proche")
      expect(assigns(:user)).to eq(relative)
    end
  end

  describe "GET #new" do
    subject { get :new }

    before { subject }

    it "returns a success response" do
      expect(response).to be_successful
    end

    it "assigns a new user" do
      expect(response.body).to include("Ajouter un proche")
      expect(assigns(:user)).to be_a_new(User)
    end
  end

  describe "POST #create" do
    subject { post :create, params: attributes }

    before { request.headers["HTTP_REFERER"] = users_informations_path }

    context "with valid params" do
      let(:attributes) do
        { user: { first_name: "Eliott", last_name: "Le Dragon" } }
      end

      it "creates a new User" do
        expect { subject }.to change(User, :count).by(1)
      end

      it "set organisation_ids for relative" do
        subject
        expect(assigns(:user).organisation_ids).to eq(user.organisation_ids)
      end

      it "redirects to user informations with the newly created user id as a param" do
        subject
        expect(response).to redirect_to(users_informations_path(created_user_id: User.last.id))
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
      relative.reload
    end

    context "with valid params" do
      let(:attributes) do
        { id: relative.id, user: { first_name: "Eliott" } }
      end

      it "creates a new User" do
        expect do
          subject
        end.to change(relative, :first_name).from("Katia").to("Eliott")
      end

      it "redirects to user informations" do
        subject
        expect(response).to redirect_to(users_informations_path)
      end
    end

    context "with invalid params" do
      let(:attributes) do
        { id: relative.id, user: { first_name: " " } }
      end

      it "does not creates a new User" do
        expect do
          subject
        end.not_to change(relative, :first_name)
      end

      it "returns a success response (i.e. to display the 'edit' template)" do
        subject
        expect(response).to be_successful
        expect(response).to render_template(:edit)
      end
    end
  end

  describe "DELETE #destroy" do
    subject(:make_request) { delete :destroy, params: { id: relative.id } }

    let(:now) { Time.zone.parse("21/07/2019 08:22") }

    before { travel_to(now) }

    it "destroys the relative" do
      expect(relative.reload).to be_persisted
      make_request
      expect { relative.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "redirects to user edit" do
      make_request
      expect(response).to redirect_to(users_informations_path)
    end
  end
end
