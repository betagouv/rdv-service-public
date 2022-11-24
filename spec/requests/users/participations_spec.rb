# frozen_string_literal: true

RSpec.describe "Users::Participants", type: :request do
  include Rails.application.routes.url_helpers

  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:rdv) { create(:rdv, :collectif, users: [user]) }

  before { sign_in user }

  # Test du new/create (tt les tests 2 fois)
  #   Test nouveau participation
  #   Test participation existe déjà
  #   Test participation réinscription

  describe "GET /users/rdvs/:rdv_id/participants" do
    it "is successful" do
      get users_rdv_participations_path(rdv)
      expect(response).to be_successful
    end
  end

  describe "GET /users/rdvs/:rdv_id/participants/new" do
    let(:rdv) { create(:rdv, :collectif, :without_users) }

    it "set a confirmation notice message for new_users_rdv_participation GET" do
      get new_users_rdv_participation_path(rdv, user_id: user.id)
      get new_users_rdv_participation_path(rdv, user_id: user2.id)
      expect(flash[:notice]).to eq("Inscription confirmée")
      expect(rdv.reload.users.count).to eq(2)
    end

    it "set a confirmation notice message for users_rdv_participations POST" do
      post users_rdv_participations_path(rdv, user_id: user.id)
      expect(rdv.reload.users.count).to eq(1)
      expect(flash[:notice]).to eq("Inscription confirmée")
    end

    context "for a collective RDV" do
      let(:other_user) { create(:user) }
      let(:user_child) { create(:user, responsible: user) }
      let(:user_other_child) { create(:user, responsible: user) }
      let(:motif) { create(:motif, collectif: true) }
      let(:rdv) { create(:rdv, users: [other_user, user_child], motif: motif) }

      it "change to other relative user" do
        post users_rdv_participations_path(rdv, user_id: user_other_child.id)
        expect(rdv.reload.users).to match_array([user_other_child, other_user])
      end
    end

    context "for a collective RDV with a responsible user" do
      let(:user) { create(:user) }
      let(:rdv) { create(:rdv, :without_users, :collectif) }

      it "create user participation with current_user" do
        post users_rdv_participations_path(rdv)
        expect(rdv.reload.users).to match_array([user])
      end
    end
  end
end
