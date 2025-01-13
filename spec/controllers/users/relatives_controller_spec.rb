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
  end

  describe "GET #new" do
    subject { get :new }

    before { subject }

    it "returns a success response" do
      expect(response).to be_successful
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
        created_user = User.last
        expect(created_user.organisation_ids).to eq(user.organisation_ids)
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

    context "quand le numéro de pré-demande ANTS est requis et passé et valide" do
      let(:attributes) do
        { user: { first_name: "Eliott", last_name: "Le Dragon", ants_pre_demande_number: "VALID12345" }, ants_pre_demande_number_required: "true" }
      end

      include_context "rdv_mairie_api_authentication"
      before { stub_ants_status_ok("VALID12345", status: "validated", appointments: []) }

      it "créé le proche avec le numéro de pré-demande" do
        expect { subject }.to change(User, :count)
        created_user = User.last
        expect(created_user.organisation_ids).to eq(user.organisation_ids)
        expect(created_user.ants_pre_demande_number).to eq("VALID12345")
        expect(response).to redirect_to(users_informations_path(created_user_id: User.last.id))
      end
    end

    context "quand le numéro de pré-demande ANTS est requis mais pas passé" do
      let(:attributes) do
        { user: { first_name: "Eliott", last_name: "Le Dragon" }, ants_pre_demande_number_required: "true" }
      end

      it "ne créé pas de proche" do
        expect { subject }.not_to change(User, :count)
        expect(response).to be_successful
        expect(response).to render_template(:new)
      end
    end

    context "quand le numéro de pré-demande ANTS est requis mais invalide" do
      let(:attributes) do
        { user: { first_name: "Eliott", last_name: "Le Dragon", ants_pre_demande_number: "blah" }, ants_pre_demande_number_required: "true" }
      end

      it "ne créé pas de proche" do
        expect { subject }.not_to change(User, :count)
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
    subject { delete :destroy, params: { id: relative.id } }

    let(:now) { Time.zone.parse("21/07/2019 08:22") }

    before { travel_to(now) }

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
