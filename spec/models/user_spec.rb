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

    subject do
      user.add_organisation(organisation)
      user.reload
      child.reload if defined?(child)
      parent.reload if defined?(parent)
    end

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

    describe "when parent has child" do
      let(:organisations) { [organisation] }

      describe "add organisation to parent" do
        let!(:user) { create(:user, organisations: []) }
        let!(:child) { create(:user, organisations: [], parent_id: user.id) }

        it { expect { subject }.to change(user, :organisation_ids).from([]).to([organisation.id]) }
        it { expect { subject }.to change(child, :organisation_ids).from([]).to([organisation.id]) }
      end

      describe "add organisation to child" do
        let!(:parent) { create(:user, organisations: []) }
        let!(:user) { create(:user, organisations: [], parent_id: parent.id) }

        it { expect { subject }.to change(user, :organisation_ids).from([]).to([organisation.id]) }
        it { expect { subject }.to change(parent, :organisation_ids).from([]).to([organisation.id]) }
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

  describe "#soft_delete" do
    let(:now) { Time.current }

    before do
      freeze_time
      child.reload if defined?(child)
      subject
    end

    subject do
      user.soft_delete(deleted_org)
      user.reload
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

    context "when user is a child" do
      let(:user) { create(:user, parent_id: create(:user).id) }
      let(:deleted_org) { nil }

      it { expect(user.organisation_ids).to be_empty }
      it { expect(user.deleted_at).to eq(now) }

      context "and has multiple organisations" do
        let(:user) { create(:user, :with_multiple_organisations, parent_id: create(:user).id) }
        let(:deleted_org) { user.organisations.first }

        it { expect(user.organisation_ids).to be_empty }
        it { expect(user.deleted_at).to eq(now) }
      end
    end

    context "when user has a child" do
      let(:user) { create(:user) }
      let!(:child) { create(:user, parent: user) }

      let(:deleted_org) { nil }

      it { expect(user.reload.organisation_ids).to be_empty }
      it { expect(user.reload.deleted_at).to eq(now) }
      it { expect(child.reload.organisation_ids).to be_empty }
      it { expect(child.reload.deleted_at).to eq(now) }

      context "and belong to an organisation" do
        let(:deleted_org) { user.organisations.first }

        it { expect(user.reload.organisation_ids).to be_empty }
        it { expect(user.reload.deleted_at).to eq(nil) }
        it { expect(child.reload.organisation_ids).to be_empty }
        it { expect(child.reload.deleted_at).to eq(nil) }
      end
    end
  end

  describe "#available_rdvs(organisation_id)" do
    let!(:organisation1) { create(:organisation) }
    let!(:organisation2) { create(:organisation) }
    let!(:parent1) { create(:user) }
    let!(:child1) { create(:user, parent_id: parent1.id) }
    let!(:parent2) { create(:user) }

    before do
      [parent1, child1, parent2].each do |user|
        create(:rdv, users: [user], organisation: organisation1)
        create(:rdv, :excused, users: [user], organisation: organisation1)
      end
      create(:rdv, users: [parent1, child1], organisation: organisation1)
    end

    it { expect(parent1.available_rdvs(organisation1.id).size).to eq(5) }
    it { expect(parent1.available_rdvs(organisation1.id)).to match_array((parent1.rdvs + child1.rdvs).uniq) }
    it { expect(child1.available_rdvs(organisation1.id)).to match_array child1.rdvs }
    it { expect(parent2.available_rdvs(organisation1.id)).to match_array parent2.rdvs }
    it { expect(parent1.available_rdvs(organisation2.id)).to be_empty }
  end
end
