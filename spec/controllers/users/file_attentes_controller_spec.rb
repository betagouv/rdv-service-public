RSpec.describe Users::FileAttentesController, type: :controller do
  let(:user) { create(:user) }
  let!(:rdv) { create(:rdv, users: [user]) }

  before do
    sign_in user
  end

  describe "POST #create_or_delete" do
    context "when rdv and user is given" do
      subject { post :create_or_delete, params: { file_attente: { rdv_id: rdv.id, user_id: user.id } } }

      it "creates a FileAttente model" do
        expect { subject }.to change(FileAttente, :count).from(0).to(1)
      end

      it "deletes a FileAttente model" do
        FileAttente.create(rdv_id: rdv.id, user_id: user.id)
        expect { subject }.to change(FileAttente, :count).from(1).to(0)
      end
    end

    context "when file attente id is given" do
      subject { post :create_or_delete, params: { file_attente: { id: file_attente.id } } }

      let!(:file_attente) { create(:file_attente, rdv: rdv, user: user) }

      it "returns a success response" do
        expect { subject }.to change(FileAttente, :count).from(1).to(0)
      end
    end
  end
end
