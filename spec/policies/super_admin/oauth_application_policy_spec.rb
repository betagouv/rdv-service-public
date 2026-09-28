RSpec.describe SuperAdmin::OauthApplicationPolicy, type: :policy do
  subject { described_class }

  context "Permitted actions for super_admin" do
    let!(:super_admin) { create(:super_admin) }
    let!(:pundit_context) { super_admin }
    let!(:oauth_application) { create(:oauth_application) }

    it_behaves_like "permit actions", :oauth_application, :index?, :show?
    it_behaves_like "not permit actions", :oauth_application, :new?, :create?, :edit?, :update?, :destroy?
  end

  context "permitted actions for support" do
    let!(:super_admin) { create(:super_admin, :support) }
    let!(:pundit_context) { super_admin }
    let!(:oauth_application) { create(:oauth_application) }

    it_behaves_like "not permit actions", :oauth_application, :index?, :show?, :new?, :create?, :edit?, :update?, :destroy?
  end
end
