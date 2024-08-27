RSpec.describe "Users::Participants", type: :request do
  include Rails.application.routes.url_helpers

  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:rdv) { create(:rdv, :collectif, :without_users) }
  let(:rdv_indiv) { create(:rdv) }
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

    describe "POST /users/rdvs/:rdv_id/participants on an individual rdv (params override by user)" do
      it "redirect because pundit auth fails" do
        post users_rdv_participations_path(rdv_indiv)
        expect(flash[:notice]).to eq(nil)
        expect(response).to redirect_to(users_rdvs_path) # Pundit redirects when authorization fails
      end
    end

    describe "POST /users/rdvs/:rdv_id/participants, norminal case" do
      it "set a confirmation notice message for users_rdv_participations POST for current_user participation" do
        post users_rdv_participations_path(rdv)
        expect(flash[:notice]).to eq("Participation confirmée")
        expect(response).to redirect_to(users_rdv_path(rdv, invitation_token: token))
      end
    end

    describe "POST /users/rdvs/:rdv_id/participants, other cases" do
      let(:rdv) { create(:rdv, :collectif, :without_users) }

      it "specific user" do
        post users_rdv_participations_path(rdv, user_id: user.id)
        expect(flash[:notice]).to eq("Participation confirmée")
        expect(rdv.reload.users.count).to eq(1)
        expect(response).to redirect_to(users_rdv_path(rdv, invitation_token: token))
      end

      context "With relatives" do
        let(:other_user) { create(:user) }
        let(:user_child) { create(:user, responsible: user) }
        let(:user_other_child) { create(:user, responsible: user) }
        let(:rdv) { create(:rdv, :collectif, users: [other_user, user_child]) }

        it "change to other relative user" do
          post users_rdv_participations_path(rdv, user_id: user_other_child.id)
          expect(flash[:notice]).to eq("Participation confirmée")
          expect(rdv.reload.users).to contain_exactly(user_other_child, other_user)
          # Change to relative isnt allowed with invitation and doesnt redirect with invitation token
          expect(response).to redirect_to(users_rdv_path(rdv))
        end
      end

      it "cannot create participation for non relatives users" do
        post users_rdv_participations_path(rdv, user_id: user.id)
        expect(flash[:notice]).to eq("Participation confirmée")
        expect(response).to redirect_to(users_rdv_path(rdv, invitation_token: token))
        post users_rdv_participations_path(rdv, user_id: user2.id)
        expect(rdv.reload.users).to contain_exactly(user)
      end
    end
  end

  describe "Participation already exist" do
    let!(:other_user) { create(:user) }
    let!(:rdv) { create(:rdv, :collectif, users: [other_user, user]) }

    it "display notice" do
      post users_rdv_participations_path(rdv, user_id: user.id)
      expect(flash[:notice]).to eq("Usager déjà inscrit")
      expect(rdv.reload.users).to contain_exactly(user, other_user)
      expect(response).to redirect_to(users_rdv_path(rdv))
    end
  end

  describe "Participation update (if excused)" do
    let(:participation1) { create(:participation, rdv: rdv, user: user) }

    it "display notice" do
      participation1.update!(status: "excused")
      expect(rdv.reload.users).to contain_exactly(user)
      post users_rdv_participations_path(rdv, user_id: user.id)
      expect(flash[:notice]).to eq("Participation confirmée")
      expect(rdv.reload.users).to contain_exactly(user)
    end
  end
end
