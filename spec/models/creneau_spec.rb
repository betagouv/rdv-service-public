RSpec.describe Creneau, type: :model do
  let(:organisation) { create(:organisation) }
  let!(:motif) { create(:motif, name: "Vaccination", default_duration_in_min: 30, organisation: organisation) }
  let!(:lieu) { create(:lieu, organisation: organisation) }
  let(:today) { Time.zone.local(2019, 9, 19) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:plage_ouverture) do
    create(:plage_ouverture, motifs: [motif], lieu: lieu, first_day: today, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(11), agent: agent, organisation: organisation)
  end

  before { travel_to(today) }

  describe "#respects_max_public_booking_delay?" do
    subject { creneau.respects_max_public_booking_delay? }

    context "creneau respects booking delays" do
      let(:creneau) { build(:creneau, :respects_booking_delays) }

      it { is_expected.to be true }
    end

    context "creneau does not respect max booking delay" do
      let(:creneau) { build(:creneau, :does_not_respect_max_public_booking_delay) }

      it { is_expected.to be false }
    end
  end

  describe "#lieu" do
    it "returns the lieu when the lieu_id is present" do
      expect(build(:creneau, lieu_id: lieu.id).lieu).to eq(lieu)
    end

    it "returns nil when the lieu_id is blank" do
      expect(build(:creneau, lieu_id: nil).lieu).to be_nil
    end
  end
end
