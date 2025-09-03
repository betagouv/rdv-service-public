RSpec.describe SuperAdmin::PrescripteurPolicy, type: :policy do
  subject { described_class }

  context "Permitted actions for super_admin" do
    let!(:super_admin) { create(:super_admin) }
    let!(:pundit_context) { super_admin }
    let!(:prescripteur) { create(:prescripteur) }

    it_behaves_like "permit actions", :prescripteur, :show?
    it_behaves_like "not permit actions", :prescripteur, :new?, :create?, :edit?, :update?, :destroy?
  end

  context "permitted actions for support" do
    let!(:super_admin) { create(:super_admin, :support) }
    let!(:pundit_context) { super_admin }
    let!(:prescripteur) { create(:prescripteur) }

    it_behaves_like "permit actions", :prescripteur, :show?
    it_behaves_like "not permit actions", :prescripteur, :new?, :create?, :edit?, :update?, :destroy?
  end
end
