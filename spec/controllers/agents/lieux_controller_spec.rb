RSpec.describe Agents::LieuxController, type: :controller do
  render_views

  let(:agent) { create(:agent, :admin) }
  let(:organisation_id) { agent.organisation_ids.first }
  let!(:lieu) { create(:lieu, organisation_id: organisation_id) }

  before do
    sign_in agent
  end

  describe 'GET #index' do
    it 'returns a success response' do
      get :index, params: { organisation_id: organisation_id }
      expect(response).to be_successful
    end
  end

  describe 'GET #new' do
    it 'returns a success response' do
      get :new, params: { organisation_id: organisation_id }
      expect(response).to be_successful
    end
  end

  describe 'GET #edit' do
    it 'returns a success response' do
      get :edit, params: { organisation_id: organisation_id, id: lieu.to_param }
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      let(:valid_attributes) do
        build(:lieu).attributes
      end

      it 'creates a new Lieu' do
        expect do
          post :create, params: { organisation_id: organisation_id, lieu: valid_attributes }
        end.to change(Lieu, :count).by(1)
      end

      it 'redirects to the created lieu' do
        post :create, params: { organisation_id: organisation_id, lieu: valid_attributes }
        expect(response).to redirect_to(organisation_lieux_path(organisation_id))
      end
    end

    context 'with invalid params' do
      let(:invalid_attributes) do
        {
          name: 'test',
        }
      end

      it 'does not create a new Lieu' do
        expect do
          post :create, params: { organisation_id: organisation_id, lieu: invalid_attributes }
        end.not_to change(Lieu, :count)
      end

      it "returns a success response (i.e. to display the 'new' template)" do
        post :create, params: { organisation_id: organisation_id, lieu: invalid_attributes }
        expect(response).to be_successful
      end
    end
  end

  describe 'PUT #update' do
    subject { put :update, params: { organisation_id: organisation_id, id: lieu.to_param, lieu: new_attributes } }

    before { subject }

    context 'with valid params' do
      let(:new_attributes) do
        {
          name: 'Le nouveau nom',
        }
      end

      it 'updates the requested lieu' do
        lieu.reload
        expect(lieu.name).to eq('Le nouveau nom')
      end

      it 'redirects to the lieu' do
        expect(response).to redirect_to(organisation_lieux_path(organisation_id))
      end
    end

    context 'with invalid params' do
      let(:new_attributes) do
        {
          name: '',
        }
      end

      it "returns a success response (i.e. to display the 'edit' template)" do
        expect(response).to be_successful
      end

      it 'does not change lieu name' do
        lieu.reload
        expect(lieu.name).not_to eq('')
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested lieu' do
      expect do
        delete :destroy, params: { organisation_id: organisation_id, id: lieu.to_param }
      end.to change(Lieu, :count).by(-1)
    end

    it 'redirects to the lieux list' do
      delete :destroy, params: { organisation_id: organisation_id, id: lieu.to_param }
      expect(response).to redirect_to(organisation_lieux_path(organisation_id))
    end
  end
end
