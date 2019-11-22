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

  describe "#set_organisation_ids_from_parent" do
    let(:user) { create(:user, organisations: [create(:organisation), create(:organisation)]) }
    let(:child) { create(:user, parent_id: parent_id) }

    describe "when there is no parent" do
      let(:parent_id) { nil }

      it { expect(child.organisation_ids).not_to eq(user.organisation_ids) }
    end

    describe "when user is parent" do
      let(:parent_id) { user.id }

      it { expect(child.organisation_ids).to eq(user.organisation_ids) }
    end
  end

  describe "children association callbacks" do
    let(:organisation) { create(:organisation) }
    let(:organisation2) { create(:organisation) }
    let(:user) { create(:user, organisations: [organisation]) }
    let(:child1) { create(:user) }
    let(:child2) { create(:user) }

    before do
      user.children << [child1, child2]
    end

    describe "#add_organisation_to_children" do
      subject { user.add_organisation(organisation2) }

      it { expect { subject }.to change(child1, :organisation_ids).from([organisation.id]).to([organisation.id, organisation2.id]) }
      it { expect { subject }.to change(child2, :organisation_ids).from([organisation.id]).to([organisation.id, organisation2.id]) }
    end

    describe "#remove_organisation_to_children" do
      subject { user.organisations.delete(organisation) }

      it { expect { subject }.to change(child1, :organisation_ids).from([organisation.id]).to([]) }
      it { expect { subject }.to change(child2, :organisation_ids).from([organisation.id]).to([]) }
    end
  end

  describe "#soft_delete" do
    let(:now) { Time.current }
    before do
      freeze_time
      user.soft_delete(deleted_org)
    end

    context 'belongs to multiple organisations and with organisation given' do
      let(:user) { create(:user, :with_multiple_organisations) }
      let(:deleted_org) { user.organisations.first }
      it { expect(user.organisation_ids).not_to include(deleted_org.id) }
      it "remove the correct organisation" do
        left_orgs_ids = Organisation.where.not(id: deleted_org.id).pluck(:id)
        expect(user.organisation_ids).to match_array(left_orgs_ids)
      end
      it { expect(user.deleted_at).to be_nil }
    end

    context 'belongs to one organisation and with organisation given' do
      let(:user) { create(:user) }
      let(:deleted_org) { user.organisations.first }
      it { expect(user.organisation_ids).to be_empty }
      it { expect(user.deleted_at).to be_nil }
    end

    context 'with no organisation given' do
      let(:user) { create(:user, :with_multiple_organisations) }
      let(:deleted_org) { nil }
      it { expect(user.organisation_ids).to be_empty }
      it { expect(user.deleted_at).not_to be_nil }
      it { expect(user.deleted_at).to eq(now) }
    end
  end
end
