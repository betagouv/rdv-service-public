# frozen_string_literal: true

describe RdvsUser, type: :model do
  describe "RdvsUser is getting Rdv parent status" do
    %w[collectif individuel].each do |rdv_type|
      describe "For #{rdv_type} rdv" do
        rdv_type == "collectif" ? let(:motif) { create :motif, :collectif } : let(:motif) { create :motif }
        let(:agent) { create :agent }
        let(:user) { create :user }
        let(:user2) { create :user }
        let(:rdv) { create :rdv, starts_at: Time.zone.tomorrow, users: [user, user2], motif: motif, agents: [agent] }

        describe "when rdv is created with user" do
          it do
            expect(rdv.rdvs_users.map(&:status)).to all(include("unknown"))
          end
        end
      end
    end
  end
end
