# frozen_string_literal: true

RSpec.describe "Users::Participants", type: :request do
  include Rails.application.routes.url_helpers

  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:rdv) { create(:rdv, :collectif, :without_users) }
  let(:token) { "12345" }

  before do
    sign_in user
    allow(Devise.token_generator).to receive(:generate).and_return("12345")
  end

  describe "Create new participation" do
    describe "GET /users/rdvs/:rdv_id/participants" do
      it "is successful" do
        get users_rdv_participations_path(rdv)
        expect(response).to be_successful
      end
    end

    describe "GET /users/rdvs/:rdv_id/participants/new, norminal case" do
      it "set a confirmation notice message for new_users_rdv_participation GET for current_user participation" do
        get new_users_rdv_participation_path(rdv)
        expect(flash[:notice]).to eq("Inscription confirmée")
        expect(response).to redirect_to(users_rdv_path(rdv, invitation_token: token))
      end
    end

    describe "POST /users/rdvs/:rdv_id/participants, norminal case" do
      it "set a confirmation notice message for users_rdv_participations POST for current_user participation" do
        get new_users_rdv_participation_path(rdv)
        expect(flash[:notice]).to eq("Inscription confirmée")
        expect(response).to redirect_to(users_rdv_path(rdv, invitation_token: token))
      end
    end

    describe "POST /users/rdvs/:rdv_id/participants, other cases" do
      let(:rdv) { create(:rdv, :collectif, :without_users) }

      it "multiple post" do
        post users_rdv_participations_path(rdv, user_id: user.id)
        post users_rdv_participations_path(rdv, user_id: user2.id)
        expect(flash[:notice]).to eq("Inscription confirmée")
        expect(rdv.reload.users.count).to eq(2)
        expect(response).to redirect_to(users_rdv_path(rdv, invitation_token: token))
      end

      it "specific user" do
        post users_rdv_participations_path(rdv, user_id: user.id)
        expect(flash[:notice]).to eq("Inscription confirmée")
        expect(rdv.reload.users.count).to eq(1)
        expect(response).to redirect_to(users_rdv_path(rdv, invitation_token: token))
      end

      context "With relatives" do
        let(:other_user) { create(:user) }
        let(:user_child) { create(:user, responsible: user) }
        let(:user_other_child) { create(:user, responsible: user) }
        let(:motif) { create(:motif, collectif: true) }
        let(:rdv) { create(:rdv, users: [other_user, user_child], motif: motif) }

        it "change to other relative user" do
          post users_rdv_participations_path(rdv, user_id: user_other_child.id)
          expect(flash[:notice]).to eq("Inscription confirmée")
          expect(rdv.reload.users).to match_array([user_other_child, other_user])
          # Change to relative isnt allowed with invitation and doesnt redirect with invitation token
          expect(response).to redirect_to(users_rdv_path(rdv))
        end
      end
    end
  end

  describe "Participation already exist" do

  end

  describe "Participation update (if excused)" do

  end
end
