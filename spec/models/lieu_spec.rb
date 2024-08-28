RSpec.describe Lieu, type: :model do
  let!(:territory) { create(:territory, departement_number: "62") }
  let!(:organisation) { create(:organisation, territory: territory) }
  let!(:user) { create(:user) }

  describe "validation" do
    subject { lieu.errors }

    it "invalid without latitude" do
      lieu = build(:lieu, latitude: nil)
      expect(lieu).to be_invalid
    end

    it "invalid without longitude" do
      lieu = build(:lieu, longitude: nil)
      expect(lieu).to be_invalid
    end

    it "return errror message about address" do
      lieu = build(:lieu, longitude: nil, latitude: nil)
      lieu.valid?
      expect(lieu.errors.full_messages).to eq(["Adresse doit être valide"])
    end

    describe "availability changes" do
      let(:lieu) { create :lieu, availability: initial_value }

      before do
        lieu.availability = new_value
        lieu.validate
      end

      context "cannot change from single_use" do
        let(:initial_value) { :single_use }
        let(:new_value) { :enabled }

        it { is_expected.to be_of_kind(:availability, :cant_change_from_or_to_single_use) }
      end

      context "cannot change to single_use" do
        let(:initial_value) { :enabled }
        let(:new_value) { :single_use }

        it { is_expected.to be_of_kind(:availability, :cant_change_from_or_to_single_use) }
      end

      context "can change between enabled and disabled" do
        let(:initial_value) { :enabled }
        let(:new_value) { :disabled }

        it { is_expected.to be_empty }
      end
    end
  end

  context "with motif" do
    let!(:motif) { create(:motif, name: "Vaccination", bookable_by: bookable_by, organisation: organisation) }
    let!(:lieu) { create(:lieu) }

    describe ".for_motif" do
      subject { described_class.for_motif(motif) }

      let!(:plage_ouverture) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu, organisation: organisation) }
      let(:bookable_by) { :agents }

      before { freeze_time }

      it { expect(subject).to contain_exactly(lieu) }

      context "with an other plage_ouverture" do
        let!(:lieu2) { create(:lieu) }
        let!(:plage_ouverture2) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu2) }

        it { expect(subject).to contain_exactly(lieu, lieu2) }
      end

      context "with a plage_ouverture not yet started" do
        let!(:lieu2) { create(:lieu) }
        let!(:plage_ouverture2) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu2, first_day: 8.days.from_now) }

        it { expect(subject).to contain_exactly(lieu, lieu2) }
      end

      context "with a plage_ouverture with no recurrence and closed" do
        let!(:lieu2) { create(:lieu) }
        let!(:plage_ouverture2) { create(:plage_ouverture, motifs: [motif], lieu: lieu2, first_day: Date.parse("2020-07-30")) }

        it { expect(subject).to contain_exactly(lieu) }
      end

      context "with a motif not active" do
        before { motif.update(deleted_at: Time.zone.now) }

        it { expect(subject).to eq([]) }
      end
    end

    describe ".distance" do
      let!(:lieu) { create(:lieu) }
      let!(:lieu_lille) { create(:lieu, latitude: 50.63, longitude: 3.053) }
      let(:paris_loc) { { latitude: 48.83, longitude: 2.37 } }
      let(:bookable_by) { :everyone }

      it { expect(lieu_lille.distance(paris_loc[:latitude], paris_loc[:longitude])).to be_a(Float) }
      it { expect(lieu_lille.distance(paris_loc[:latitude], paris_loc[:longitude])).to be_within(10_000).of(204_000) }
    end

    describe "#with_open_slots_for_motifs" do
      subject { described_class.with_open_slots_for_motifs([motif]) }

      let!(:motif) { create(:motif, name: "Vaccination") }

      let!(:lieu) { create(:lieu) }

      context "for a motif individuel" do
        context "motif has current plage ouvertures" do
          let!(:plage_ouverture) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu) }

          it { is_expected.to include(lieu) }
        end

        context "motif has finished plage ouverture" do
          let!(:plage_ouverture) { create(:plage_ouverture, :daily, motifs: [motif], lieu: lieu, first_day: 2.days.ago, recurrence: nil) }

          it { is_expected.not_to include(lieu) }
        end

        context "motif has no plage ouvertures" do
          let(:plage_ouverture) { nil }

          it { is_expected.not_to include(lieu) }
        end
      end

      context "for a motif collectif" do
        let!(:motif) { create(:motif, collectif: true) }

        before do
          create(:rdv, :collectif, motif: motif, lieu: lieu) # valid rdv
          create(:rdv, :collectif, motif: motif, status: :revoked)
          create(:rdv, :collectif, motif: motif, max_participants_count: 3).tap do |rdv| # fully booked
            rdv.update_columns(users_count: 3) # rubocop:disable Rails/SkipsModelValidations
          end
          create(:rdv, :collectif, motif: motif, starts_at: 3.days.ago) # in the past
        end

        it "only returns lieux with a rdv that is available for reservation" do
          expect(subject).to contain_exactly(lieu)
        end

        context "for a single use lieu" do
          let!(:lieu) { create(:lieu, availability: :single_use) }

          it { is_expected.to contain_exactly(lieu) }
        end
      end
    end
  end

  describe "#destroy" do
    it "dont destroy lieu when it have rdvs" do
      lieu = create(:lieu, organisation: organisation, rdvs: [create(:rdv)])
      expect(lieu.destroy).to be(false)
    end

    it "dont destroy lieu when it have plage_ouvertures" do
      lieu = create(:lieu, organisation: organisation, plage_ouvertures: [create(:plage_ouverture)])
      expect(lieu.destroy).to be(false)
    end

    it "destroy lieu without rdvs or plage d'ouverture" do
      lieu = create(:lieu, organisation: organisation, rdvs: [], plage_ouvertures: [])
      expect(lieu.destroy).to eq(lieu)
    end
  end

  describe "#enabled=" do
    it "enable a disabled lieu" do
      lieu = build :lieu, availability: :disabled
      lieu.enabled = true
      expect(lieu.availability).to eq "enabled"
    end

    it "disable an enabled lieu" do
      lieu = build :lieu, availability: :enabled
      lieu.enabled = false
      expect(lieu.availability).to eq "disabled"
    end
  end
end
