# frozen_string_literal: true

describe Admin::RdvUserPresenter do
  let(:organisation) { create(:organisation) }
  let(:user) { create(:user, organisations: [organisation]) }

  describe "#previous_rdvs_truncated" do
    it "returns no previous RDVs" do
      rdv = create(:rdv, users: [user], organisation: organisation)

      expect(described_class.new(rdv, user).previous_rdvs_truncated).to be_empty
    end

    it "returns single previous RDV" do
      rdv = create(:rdv, users: [user], organisation: organisation)
      previous_rdv = create(:rdv, starts_at: rdv.starts_at - 1.day, organisation: organisation, users: [user])

      expect(described_class.new(rdv, user).previous_rdvs_truncated).to eq([previous_rdv])
    end

    it "returns 6 previous RDVs" do
      now = Time.zone.parse("2020-02-12 12:00")
      travel_to(now - 1.month)
      rdv = create(:rdv, starts_at: now - 1.hour, users: [user], organisation: organisation)
      p4 = create(:rdv, starts_at: now - 7.days, organisation: organisation, users: [user])
      p5 = create(:rdv, starts_at: now - 13.days, organisation: organisation, users: [user])
      p1 = create(:rdv, starts_at: now - 1.day, organisation: organisation, users: [user])
      create(:rdv, starts_at: now - 16.days, organisation: organisation, users: [user])
      p2 = create(:rdv, starts_at: now - 2.days, organisation: organisation, users: [user])
      p3 = create(:rdv, starts_at: now - 4.days, organisation: organisation, users: [user])
      travel_to(now)

      expect(described_class.new(rdv, user).previous_rdvs_truncated).to eq([p1, p2, p3, p4, p5])
    end

    it "returns with next RDVs" do
      now = Time.zone.local(2020, 5, 23, 15, 56)
      travel_to(now - 6.days)
      rdv = create(:rdv, organisation: organisation, users: [user], starts_at: now - 2.days)
      previous_rdv = create(:rdv, starts_at: now - 4.days, organisation: organisation, users: [user])
      create(:rdv, starts_at: now + 4.days, organisation: organisation, users: [user])
      travel_to(now)

      expect(described_class.new(rdv, user).previous_rdvs_truncated).to eq([previous_rdv])
    end
  end
end
