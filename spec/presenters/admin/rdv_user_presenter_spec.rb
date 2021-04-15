describe Admin::RdvUserPresenter do
  describe "#previous_rdvs_truncated" do
    subject { described_class.new(rdv, user).previous_rdvs_truncated }

    context "no previous RDVs" do
      let!(:organisation) { create(:organisation) }
      let!(:user) { create(:user, organisations: [organisation]) }
      let(:rdv) { create(:rdv, users: [user], organisation: organisation) }

      it { is_expected.to be_empty }
    end

    context "single previous RDV" do
      let!(:organisation) { create(:organisation) }
      let!(:user) { create(:user, organisations: [organisation]) }
      let(:rdv) { create(:rdv, users: [user], organisation: organisation) }
      let!(:previous_rdv) { create(:rdv, starts_at: rdv.starts_at - 1.day, organisation: organisation, users: [user]) }

      it { is_expected.to eq([previous_rdv]) }
    end

    context "6 previous RDVs" do
      let!(:organisation) { create(:organisation) }
      let!(:user) { create(:user, organisations: [organisation]) }
      let(:rdv) { create(:rdv, users: [user], organisation: organisation) }
      let!(:p4) { create(:rdv, starts_at: rdv.starts_at - 7.days, organisation: organisation, users: [user]) }
      let!(:p5) { create(:rdv, starts_at: rdv.starts_at - 13.days, organisation: organisation, users: [user]) }
      let!(:p1) { create(:rdv, starts_at: rdv.starts_at - 1.day, organisation: organisation, users: [user]) }
      let!(:p6) { create(:rdv, starts_at: rdv.starts_at - 16.days, organisation: organisation, users: [user]) }
      let!(:p2) { create(:rdv, starts_at: rdv.starts_at - 2.days, organisation: organisation, users: [user]) }
      let!(:p3) { create(:rdv, starts_at: rdv.starts_at - 4.days, organisation: organisation, users: [user]) }

      it { is_expected.to eq([p1, p2, p3, p4, p5]) }
    end

    context "with next RDVs" do
      let(:some_date) { Time.new(2020, 5, 23, 15, 56) }
      let!(:organisation) { create(:organisation) }
      let!(:user) { create(:user, organisations: [organisation]) }
      let!(:rdv) { create(:rdv, organisation: organisation, users: [user], starts_at: some_date - 2.days) }
      let!(:previous_rdv) { create(:rdv, starts_at: rdv.starts_at - 4.days, organisation: organisation, users: [user]) }
      let!(:next_rdv) { create(:rdv, starts_at: rdv.starts_at + 4.days, organisation: organisation, users: [user]) }

      it { is_expected.to eq([previous_rdv]) }
    end
  end
end
