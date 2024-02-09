RSpec.describe SuperAdmin::ServicePolicy, type: :policy do
  subject { described_class }

  let!(:super_admin) { create(:super_admin) }
  let!(:pundit_context) { super_admin }
  let!(:service) { create(:service) }

  context "Permitted actions for super_admin" do
    it_behaves_like "permit actions", :service, :index?, :show?, :new?, :create?, :edit?, :update?, :destroy?
  end

  context "permitted actions for support" do
    let!(:pundit_context) { create(:super_admin, :support) }

    it_behaves_like "permit actions", :service, :index?, :show?
    it_behaves_like "not permit actions", :service, :new?, :create?, :edit?, :update?, :destroy?
  end
end
