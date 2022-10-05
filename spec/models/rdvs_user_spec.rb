# frozen_string_literal: true

describe RdvsUser, type: :model do
  describe "RdvsUser is getting Rdv parent status" do
    %w[collectif individuel].each do |rdv_type|
      describe "For #{rdv_type} rdv" do
        rdv_type == "collectif" ? let(:motif) { create :motif, :collectif } : let(:motif) { create :motif }
        let(:user) { create :user }
        let(:user2) { create :user }
        let(:rdv) { create :rdv, starts_at: Time.zone.tomorrow, users: [user, user2], motif: motif }

        describe "when rdv is created with user" do
          it do
            expect(rdv.rdvs_users.map(&:status)).to all(include("unknown"))
          end
        end

        describe "when rdv is globally revoked" do
          it do
            rdv.update(status: "revoked")
            expect(rdv.rdvs_users.reload.map(&:status)).to all(include("revoked"))
          end
        end

        describe "when rdv is globally seen" do
          it do
            rdv.update(status: "seen")
            expect(rdv.rdvs_users.reload.map(&:status)).to all(include("seen"))
          end
        end

        describe "when rdv is globally noshow" do
          it do
            rdv.update(status: "noshow")
            expect(rdv.rdvs_users.reload.map(&:status)).to all(include("noshow"))
          end
          it do
            rdv.update(status: "noshow")
            expect(rdv.rdvs_users.reload.map(&:status)).to all(include("noshow"))
          end
        end

        describe "when rdv is globally excused" do
          it do
            rdv.update(status: "excused")
            if rdv_type == "collectif"
              # Collective rdv cannot be set as excused in frontend (TODO validation in backend), this is individual behavior only
              expect(rdv.rdvs_users.reload.map(&:status)).to all(include("unknown"))
            else
              expect(rdv.rdvs_users.reload.map(&:status)).to all(include("excused"))
            end
          end
        end

        # if status_before_last_save != "unknown" && status == "unknown"
        #   rdvs_users.update(status: "unknown")
        # end
    
        # if !collectif? && status == "excused"
        #   rdvs_users.not_cancelled.update(status: "excused")
        # end
        # rdvs_users.not_cancelled.update(status: "revoked") if status == "revoked"
        # rdvs_users.not_cancelled.where(status: "unknown").update(status: "seen") if status == "seen"
        # rdvs_users.not_cancelled.where(status: "unknown").update(status: "noshow") if status == "noshow"

      end
    end
  end
end
