# frozen_string_literal: true

describe Users::CreneauSearch do
  let(:organisation) { create(:organisation) }
  let(:user) { create(:user) }
  let(:motif) { create(:motif, name: "Coucou", location_type: :home, organisation: organisation) }
  let(:lieu) { create(:lieu, organisation: organisation) }
  let(:starts_at) { Time.zone.parse("2020-10-20 09:30") }
  let(:now) { Time.zone.parse("2020-10-19 14:30") }

  describe ".creneau_for" do
    subject do
      described_class.creneau_for(
        user: user,
        motif: motif,
        lieu: lieu,
        starts_at: starts_at
      )
    end

    before do
      travel_to(now)
      allow(SlotBuilder).to receive(:available_slots).and_return(mock_creneaux)
    end

    context "some matching creneaux" do
      let(:mock_creneaux) do
        [
          build(:creneau, starts_at: Time.zone.parse("2020-10-20 09:30")),
          build(:creneau, starts_at: Time.zone.parse("2020-10-20 10:00")),
          build(:creneau, starts_at: Time.zone.parse("2020-10-20 10:30")),
        ]
      end

      it { is_expected.to eq(mock_creneaux[0]) }
    end

    context "no matching creneaux" do
      let(:mock_creneaux) do
        [
          build(:creneau, starts_at: Time.zone.parse("2020-10-20 10:00")),
          build(:creneau, starts_at: Time.zone.parse("2020-10-20 10:30")),
          build(:creneau, starts_at: Time.zone.parse("2020-10-20 11:30")),
        ]
      end

      it { is_expected.to be_nil }
    end

    context "no creneaux built at all" do
      let(:mock_creneaux) { [] }

      it { is_expected.to be_nil }
    end
  end
end
