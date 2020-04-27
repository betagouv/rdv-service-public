RSpec.describe Users::RelativesController, type: :controller do
  render_views

  let(:user) { create(:user) }
  let!(:relative) { create(:user, first_name: "Katia", last_name: "Garcia", birth_date: Date.parse("12/10/1990"), responsible_id: user.id) }

  before do
    travel_to(Time.zone.local(2019, 7, 20))
    sign_in user
  end

  after { travel_back }

  describe "GET #edit" do
    subject { get :edit, params: { id: relative.id } }

    before { subject }

    it "returns a success response" do
      expect(response).to be_successful
    end

    it "should assign relative" do
      expect(response.body).to include("Modifier un proche")
      expect(assigns(:user)).to eq(relative)
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

      it "set organisation_ids for relative" do
        subject
        expect(assigns(:user).organisation_ids).to eq(user.organisation_ids)
      end

      it "redirects to user informations with a success flash" do
        subject
        expect(flash[:success]).to be_present
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

      it "also redirects but with an error flash" do
        subject
        expect(flash[:error]).to be_present
        expect(response).to redirect_to(users_informations_path)
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
    subject { delete :destroy, params: { id: relative.id } }
    let(:now) { "21/07/2019 08:22".to_time }

    before { travel_to(now) }
    after { travel_back }

    it "soft deletes the relative" do
      expect do
        subject
      end.to change { relative.reload.deleted_at }.from(nil).to(now)
    end

    it "redirects to user edit" do
      subject
      expect(response).to redirect_to(users_informations_path)
    end
  end
end
