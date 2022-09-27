# frozen_string_literal: true

describe RdvsUser, type: :model do
  describe "RdvsUser is getting Rdv parent status" do
    %w[collectif individuel].each do |rdv_type|
      describe "For #{rdv_type} rdv" do
        rdv_type == "collectif" ? let(:motif) { create :motif, :collectif } : let(:motif) { create :motif }
        let(:user) { create :user }
        let(:rdv) { create :rdv, starts_at: Time.zone.tomorrow, users: [user], motif: motif }

        describe "when rdv is created with user" do
          it do
            expect(rdv.status).to eq(rdv.rdvs_users.first.status)
          end
        end

        describe "when rdv is updated" do
          it do
            rdv.update(status: "seen")
            expect(rdv.reload.rdvs_users.first.status).to eq("seen")
          end
        end
      end
    end
  end
end
