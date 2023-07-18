# frozen_string_literal: true

describe Api::V1::UsersController, type: :controller do
  let(:user) { create(:user) }

  before do
    allow(controller).to receive(:authorize).and_return(true)
    allow(controller).to receive(:authenticate_agent).and_return(true)
  end

  describe "#update" do
    subject do
      patch :update, params: params
    end

    let(:params) do
      {
        id: user.id,
        first_name: "John",
        birth_name: "Doe",
        address: "1 rue de la paix",
        email: user.email,
      }
    end

    it "updates the user" do
      subject
      expect(response).to have_http_status(:ok)
      expect(user.reload.first_name).to eq("John")
      expect(user.reload.birth_name).to eq("Doe")
    end

    context "when the user is frozen by franceconnect" do
      before do
        user.update!(logged_once_with_franceconnect: true)
      end

      it "updates only non frozen attributes" do
        subject
        expect(response).to have_http_status(:ok)
        expect(user.reload.first_name).not_to eq("John")
        expect(user.reload.birth_name).not_to eq("Doe")
        expect(user.reload.address).to eq("1 rue de la paix")
      end
    end
  end
end
