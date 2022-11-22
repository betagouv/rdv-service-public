# frozen_string_literal: true

describe RdvsUser, type: :model do
  describe "RdvsUser is getting Rdv parent status" do
    %w[collectif individuel].each do |rdv_type|
      describe "For #{rdv_type} rdv" do
        rdv_type == "collectif" ? let(:motif) { create(:motif, :collectif) } : let(:motif) { create(:motif) }
        let(:agent) { create(:agent) }
        let(:user) { create(:user) }
        let(:user2) { create(:user) }
        let(:rdv) { create(:rdv, starts_at: Time.zone.tomorrow, users: [user, user2], motif: motif, agents: [agent]) }

        describe "when rdv is created with user" do
          it do
            expect(rdv.rdvs_users.map(&:status)).to all(include("unknown"))
          end
        end
      end
    end
  end

  describe "Change in Rdvs_Users update rdv.users_count" do
    let(:agent) { create(:agent) }
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }
    let!(:user3) { create(:user) }
    let(:rdv) { create(:rdv, :collectif, starts_at: Time.zone.tomorrow, agents: [agent], users: [user1, user2, user3]) }

    it "correctly add in users_count" do
      expect(rdv.users_count).to eq(3)
    end

    it "correctly remove in users_count" do
      rdv.rdvs_users.last.destroy
      expect(rdv.reload.users_count).to eq(2)
    end

    it "dont count canceled" do
      new_rdvs_user = create(:rdvs_user, rdv: rdv)
      new_rdvs_user.status = "excused"
      new_rdvs_user.save
      expect(rdv.users.count).to eq(4)
      expect(rdv.users_count).to eq(3)
    end
  end

  describe "Add/Remove rdvs_users update rdv parent status (touch hook)" do
    let(:agent) { create(:agent) }
    let!(:rdv) do
      create(:rdv,
             :collectif,
             starts_at: Time.zone.tomorrow,
             agents: [agent],
             status: "seen",
             rdvs_users: [rdvs_user1, rdvs_user2, rdvs_user3])
    end
    let(:rdvs_user1) { create(:rdvs_user) }
    let(:rdvs_user2) { create(:rdvs_user) }
    let(:rdvs_user3) { create(:rdvs_user) }

    before do
      rdvs_user1.update!(status: "seen")
      rdvs_user2.update!(status: "seen")
      rdvs_user3.update!(status: "seen")
    end

    it "Add Rdvs_user update rdv parent status" do
      expect(rdv.rdvs_users.reload.map(&:status)).to all(include("seen"))
      expect(rdv.status).to eq("seen")
      create(:rdvs_user, rdv: rdv)
      expect(rdv.reload.status).to eq("unknown")
    end

    it "Remove Rdvs_user update rdv parent status" do
      new_rdvs_user = create(:rdvs_user, rdv: rdv)
      expect(rdv.status).to eq("unknown")
      rdv.rdvs_users.destroy(new_rdvs_user)
      expect(rdv.reload.status).to eq("seen")
    end
  end
end
