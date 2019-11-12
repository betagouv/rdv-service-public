describe User, type: :model do
  describe '#age' do
    let(:user) { build(:user, birth_date: birth_date) }

    context 'born 4 years ago' do
      let(:birth_date) { 4.years.ago }

      it { expect(user.age).to eq("4 ans") }
    end

    context 'born 4 years + 1 day ago' do
      let(:birth_date) { 4.years.ago + 1.day }

      it { expect(user.age).to eq("3 ans") }
    end

    context 'born 2 months ago' do
      let(:birth_date) { 2.months.ago }

      it { expect(user.age).to eq("2 mois") }
    end

    context 'born 23 months ago' do
      let(:birth_date) { 23.months.ago }

      it { expect(user.age).to eq("23 mois") }
    end

    context 'born 24 months ago' do
      let(:birth_date) { 24.months.ago }

      it { expect(user.age).to eq("2 ans") }
    end

    context 'born 20 days ago' do
      let(:birth_date) { 20.days.ago }

      it { expect(user.age).to eq("20 jours") }
    end
  end

  describe "#add_organisation" do
    let(:user) { create(:user, organisations: organisations) }
    let(:organisation) { create(:organisation) }

    subject { user.add_organisation(organisation) }

    describe "when organisation is not associated" do
      let(:organisations) { [] }
      it { expect { subject }.to change(user, :organisation_ids).from([]).to([organisation.id]) }
    end

    describe "when organisation is associated" do
      let(:organisations) { [organisation] }
      it { expect { subject }.not_to change(user, :organisation_ids) }

      describe "with many organisations" do
        let(:organisations) { [organisation, create(:organisation)] }
        it { expect { subject }.not_to change(user, :organisation_ids) }
      end
    end
  end
end
