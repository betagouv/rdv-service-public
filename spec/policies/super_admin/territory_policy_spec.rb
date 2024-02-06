describe SuperAdmin::TerritoryPolicy, type: :policy do
  subject { described_class }

  let!(:super_admin) { create(:super_admin) }
  let!(:pundit_context) { super_admin }
  let!(:territory) { create(:territory) }

  context "Permitted actions for super_admin" do
    it_behaves_like "permit actions", :territory, :index?, :show?, :edit?, :update?, :destroy?
  end

  context "permitted actions for support" do
    let!(:pundit_context) { create(:super_admin, :support) }

    it_behaves_like "permit actions", :territory, :index?, :show?, :edit?, :update?
    it_behaves_like "not permit actions", :territory, :destroy?
  end
end
