RSpec.describe ApplicationHelper do
  describe "#email_login_disabled_for_rdv?" do
    let(:territory) { create(:territory) }
    let(:organisation) { create(:organisation, territory: territory) }
    let(:motif) { create(:motif, organisation: organisation) }
    let(:rdv) { build(:rdv, motif: motif, organisation: organisation) }

    context "when rdv_wizard is nil" do
      it "returns false" do
        current_domain = Domain::RDV_SERVICE_PUBLIC
        helper.define_singleton_method(:current_domain) { current_domain }
        expect(helper.email_login_disabled_for_rdv?(nil)).to be false
      end
    end

    context "when on RDV_SERVICE_PUBLIC domain with territory_id 2" do
      let(:territory) { create(:territory, id: 2) }
      let(:rdv_wizard) { instance_double(Users::RdvBuilder, rdv: rdv) }

      it "returns true" do
        current_domain = Domain::RDV_SERVICE_PUBLIC
        helper.define_singleton_method(:current_domain) { current_domain }
        expect(helper.email_login_disabled_for_rdv?(rdv_wizard)).to be true
      end
    end

    context "when on RDV_SERVICE_PUBLIC domain with a different territory_id" do
      let(:rdv_wizard) { instance_double(Users::RdvBuilder, rdv: rdv) }

      it "returns false" do
        current_domain = Domain::RDV_SERVICE_PUBLIC
        helper.define_singleton_method(:current_domain) { current_domain }
        expect(helper.email_login_disabled_for_rdv?(rdv_wizard)).to be false
      end
    end

    context "when on RDV_SOLIDARITES domain with territory_id 2" do
      let(:territory) { create(:territory, id: 2) }
      let(:rdv_wizard) { instance_double(Users::RdvBuilder, rdv: rdv) }

      it "returns false" do
        current_domain = Domain::RDV_SOLIDARITES
        helper.define_singleton_method(:current_domain) { current_domain }
        expect(helper.email_login_disabled_for_rdv?(rdv_wizard)).to be false
      end
    end
  end
end
