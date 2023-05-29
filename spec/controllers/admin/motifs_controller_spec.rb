# frozen_string_literal: true

RSpec.describe Admin::MotifsController, type: :controller do
  render_views

  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }
  let!(:motif) { create(:motif, organisation_id: organisation.id) }

  before do
    sign_in agent
  end

  describe "GET #index" do
    it "returns a success response" do
      get :index, params: { organisation_id: organisation.id }
      expect(response).to be_successful
    end

    context "with a filter query parameter" do
      it "returns motif list where name match" do
        bla_motif = create(:motif, name: "Bla", organisation: organisation)
        get :index, params: { organisation_id: organisation.id, search: "bla" }
        expect(assigns(:motifs)).to eq([bla_motif])
        expect(assigns(:unfiltered_motifs).sort).to eq([bla_motif, motif].sort)
      end
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      get :show, params: { organisation_id: organisation.id, id: motif.to_param }
      expect(response).to be_successful
    end
  end

  describe "GET #new" do
    it "returns a success response" do
      get :new, params: { organisation_id: organisation.id }
      expect(response).to be_successful
    end
  end

  describe "GET #edit" do
    it "returns a success response" do
      get :edit, params: { organisation_id: organisation.id, id: motif.to_param }
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      let(:valid_attributes) do
        build(:motif, service: create(:service)).attributes
      end

      it "creates a new Motif" do
        expect do
          post :create, params: { organisation_id: organisation.id, motif: valid_attributes }
        end.to change(Motif, :count).by(1)
      end

      it "redirects to the created motif" do
        post :create, params: { organisation_id: organisation.id, motif: valid_attributes }
        expect(response).to redirect_to(admin_organisation_motifs_path(organisation.id))
      end
    end

    context "with invalid params" do
      let(:invalid_attributes) do
        {
          name: "test motif",
        }
      end

      it "does not create a new Motif" do
        expect do
          post :create, params: { organisation_id: organisation.id, motif: invalid_attributes }
        end.not_to change(Motif, :count)
      end

      it "returns a success response (i.e. to display the 'new' template)" do
        post :create, params: { organisation_id: organisation.id, motif: invalid_attributes }
        expect(response).to be_successful
      end
    end

    context "with old archived motif name" do
      subject do
        post :create, params: { organisation_id: organisation.id, motif: valid_attributes }
      end

      let!(:old_motif) { create(:motif, archived_at: Time.zone.now) }
      let(:valid_attributes) do
        build(:motif, name: old_motif.name, service: create(:service)).attributes
      end

      it "creates a new Motif" do
        expect { subject }.to change(Motif, :count).by(1)
      end
    end
  end

  describe "PUT #update" do
    subject { put :update, params: { organisation_id: organisation.id, id: motif.to_param, motif: new_attributes } }

    before { subject }

    context "with valid params" do
      let(:new_attributes) do
        {
          name: "Le nouveau nom",
        }
      end

      it "updates the requested motif" do
        motif.reload
        expect(motif.name).to eq("Le nouveau nom")
      end

      it "redirects to the motif" do
        expect(response).to redirect_to(admin_organisation_motif_path(organisation.id, motif))
      end
    end

    context "with invalid params" do
      let(:new_attributes) do
        {
          name: "",
        }
      end

      it "returns a success response (i.e. to display the 'edit' template)" do
        expect(response).to be_successful
      end

      it "does not change motif name" do
        motif.reload
        expect(motif.name).not_to eq("")
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested motif" do
      expect do
        delete :destroy, params: { organisation_id: organisation.id, id: motif.to_param }
      end.to change(Motif, :count).by(-1)
    end

    it "redirects to the motifs list" do
      delete :destroy, params: { organisation_id: organisation.id, id: motif.to_param }
      expect(response).to redirect_to(admin_organisation_motifs_path(organisation.id))
    end
  end
end
