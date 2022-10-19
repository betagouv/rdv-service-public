# frozen_string_literal: true

RSpec.describe "Users::Participants", type: :request do
  include Rails.application.routes.url_helpers

  let(:user) { create(:user) }
  let(:rdv) { create(:rdv, users: [user]) }

  before { sign_in user }

  describe "GET /users/rdvs/:rdv_id/participants" do
    it "is successful" do
      get users_rdv_participants_path(rdv)
      expect(response).to be_successful
    end
  end

  describe "POST /users/rdvs/:rdv_id/participants" do
    let(:rdv) { create(:rdv, users: [user]) }

    it "is redirect" do
      post users_rdv_participants_path(rdv, user_id: user.id)
      expect(response).to redirect_to(users_rdv_path(rdv))
    end

    it "set a confirmation notice message" do
      post users_rdv_participants_path(rdv, user_id: user.id)
      expect(flash[:notice]).to eq("Inscription confirmée")
    end

    context "for a individual RDV" do
      let(:other_user) { create(:user, responsible: user) }
      let(:motif) { create(:motif, collectif: false) }
      let(:rdv) { create(:rdv, users: [user], motif: motif) }

      it "set user" do
        expect do
          post users_rdv_participants_path(rdv, user_id: other_user.id)
        end.to change { rdv.reload.users }.from([user]).to([other_user])
      end
    end

    context "for a collective RDV" do
      let(:other_user) { create(:user) }
      let(:user_child) { create(:user, responsible: user) }
      let(:user_other_child) { create(:user, responsible: user) }
      let(:motif) { create(:motif, collectif: true) }
      let(:rdv) { create(:rdv, users: [other_user, user_child], motif: motif) }

      it "change to responsible user" do
        post users_rdv_participants_path(rdv, user_id: user_child.id)
        expect(rdv.reload.users).to match_array([user_child, other_user])
      end

      it "change to other relative user" do
        post users_rdv_participants_path(rdv, user_id: user_other_child.id)
        expect(rdv.reload.users).to match_array([user_other_child, other_user])
      end
    end

    context "for a collective RDV with a responsible user" do
      let(:user) { create(:user, responsible: nil) }
      let(:motif) { create(:motif, collectif: true) }
      let(:rdv) { create(:rdv, users: [], motif: motif) }

      it "create user participation with current_user" do
        post users_rdv_participants_path(rdv)
        expect(rdv.reload.users).to match_array([user])
      end
    end
  end
end
