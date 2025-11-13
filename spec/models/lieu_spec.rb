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

      let!(:plage_ouverture) { create(:plage_ouverture, :weekdays, motifs: [motif], lieu: lieu, organisation: organisation) }
      let(:bookable_by) { :agents }

      before { freeze_time }

      it { expect(subject).to contain_exactly(lieu) }

      context "with an other plage_ouverture" do
        let!(:lieu2) { create(:lieu) }
        let!(:plage_ouverture2) { create(:plage_ouverture, :weekdays, motifs: [motif], lieu: lieu2) }

        it { expect(subject).to contain_exactly(lieu, lieu2) }
      end

      context "with a plage_ouverture not yet started" do
        let!(:lieu2) { create(:lieu) }
        let!(:plage_ouverture2) { create(:plage_ouverture, :weekdays, motifs: [motif], lieu: lieu2, first_day: 8.days.from_now) }

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
          let!(:plage_ouverture) { create(:plage_ouverture, :weekdays, motifs: [motif], lieu: lieu) }

          it { is_expected.to include(lieu) }
        end

        context "motif has finished plage ouverture" do
          let!(:plage_ouverture) { create(:plage_ouverture, :weekdays, motifs: [motif], lieu: lieu, first_day: 2.days.ago, recurrence: nil) }

          it { is_expected.not_to include(lieu) }
        end

        context "motif has no plage ouvertures" do
          let(:plage_ouverture) { nil }

          it { is_expected.not_to include(lieu) }
        end
      end

      context "for a motif collectif" do
        let!(:motif) { create(:motif, collectif: true, organisation:) }

        before do
          create(:rdv, :collectif, motif: motif, lieu: lieu, organisation:) # valid rdv
          create(:rdv, :collectif, motif: motif, status: :revoked, organisation:)
          create(:rdv, :collectif, motif: motif, max_participants_count: 3, organisation:).tap do |rdv| # fully booked
            rdv.update_columns(users_count: 3) # rubocop:disable Rails/SkipsModelValidations
          end
          create(:rdv, :collectif, motif: motif, starts_at: 3.days.ago, organisation:) # in the past
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
    let!(:lieu) { create(:lieu, organisation:) }

    context "quand le lieu n'a ni rendez-vous ni plage d'ouverture" do
      it "détruit le lieu" do
        expect(lieu.destroy).to be_truthy
        expect(described_class.find_by(id: lieu.id)).to be_nil
      end
    end

    context "quand le lieu a seulement des plages d'ouverture expirées" do
      let!(:expired_plage_ouverture) { create(:plage_ouverture, lieu:, first_day: 2.days.ago, recurrence: nil) }

      it "détruit le lieu et la plage d'ouverture" do
        expect(lieu.destroy).to be_truthy
        expect(described_class.find_by(id: lieu.id)).to be_nil
        expect(PlageOuverture.find_by(id: expired_plage_ouverture.id)).to be_nil
      end
    end

    context "quand le lieu a seulement des plages d'ouverture à venir" do
      let!(:upcoming_plage_ouverture) { create(:plage_ouverture, lieu:, first_day: 2.days.from_now) }

      it "ne détruit pas le lieu et lève une erreur" do
        expect(lieu.destroy).to be false
        expect(described_class.find_by(id: lieu.id)).to eq(lieu)
        expect(PlageOuverture.find_by(id: upcoming_plage_ouverture.id)).to eq(upcoming_plage_ouverture)
      end
    end

    context "quand le lieu a des plages d'ouverture expirées et à venir" do
      let!(:expired_plage_ouverture) { create(:plage_ouverture, lieu:, first_day: 2.days.ago, recurrence: nil) }
      let!(:upcoming_plage_ouverture) { create(:plage_ouverture, lieu:, first_day: 2.days.from_now) }

      it "ne détruit pas le lieu et aucune plage d'ouverture n'est détruite" do
        expect(lieu.destroy).to be false
        expect(described_class.find_by(id: lieu.id)).not_to be_nil
        expect(PlageOuverture.find_by(id: expired_plage_ouverture.id)).not_to be_nil
        expect(PlageOuverture.find_by(id: upcoming_plage_ouverture.id)).not_to be_nil
      end
    end

    context "quand le lieu a des rendez-vous" do
      before { create(:rdv, lieu:, organisation:) }

      it "ne détruit pas le lieu" do
        expect(lieu.reload.destroy).to be false # reload is necessary here for some reason
        expect(lieu.errors.full_messages).to include("Vous ne pouvez pas supprimer l'enregistrement parce que des rdvs dépendant(e)s existent")
        expect(lieu.rdvs.count).to eq 1
      end
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

  describe "code_postal" do
    it "est extrait de l'adresse lorsque celle-ci est définie" do
      # Formats classiques trouvés en base
      expect(described_class.new(address: "7 rue de l'adresse, Ville, 12345").code_postal).to eq("12345")
      expect(described_class.new(address: "430 AV JEAN JAURES  46000 CAHORS").code_postal).to eq("46000")

      # Pas de code postal présent (ça arrrive)
      expect(described_class.new(address: "53 avenue de Fontainebleau").code_postal).to be_nil

      # Ne pas matcher les suites de plus de 5 chiffres
      expect(described_class.new(address: "1234567 AV JEAN JAURES  46000 CAHORS CEDEX 1234567").code_postal).to eq("46000")

      # En cas d'ambigüité, on reste prudent et on retourne nil
      expect(described_class.new(address: "67 AV JEAN JAURES, batiment 12345, 46000 CAHORS").code_postal).to be_nil

    end
  end
end
