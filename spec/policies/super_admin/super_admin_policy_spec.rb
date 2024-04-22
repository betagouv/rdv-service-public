RSpec.describe SuperAdmin::SuperAdminPolicy, type: :policy do
  subject { described_class }

  let!(:super_admin) { create(:super_admin) }
  let!(:pundit_context) { super_admin }
  let!(:new_legacy_admin_member) { build(:super_admin) }

  context "Permitted actions for super_admin" do
    it_behaves_like "permit actions", :new_legacy_admin_member, :index?, :destroy?
  end

  context "permitted actions for support on super_admin role" do
    let!(:pundit_context) { create(:super_admin, :support) }

    it_behaves_like "permit actions", :new_legacy_admin_member, :index?, :destroy?
  end

  context "permitted actions for support on support role" do
    let!(:pundit_context) { create(:super_admin, :support) }
    let!(:new_support_member) { build(:super_admin, :support) }

    it_behaves_like "permit actions", :new_support_member, :index?, :destroy?
  end
end
