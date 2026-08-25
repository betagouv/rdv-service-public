RSpec.describe Agent::OrganisationPolicy, type: :policy do
  subject { described_class }

  let(:pundit_context) { agent }
  let!(:organisation) { create(:organisation) }

  describe "#show?" do
    context "basic agent in organisation" do
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

      permissions(:show?) { it { is_expected.to permit(pundit_context, organisation) } }
    end

    context "admin agent in organisation" do
      let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

      permissions(:show?) { it { is_expected.to permit(pundit_context, organisation) } }
    end

    context "agent not in organisation" do
      let!(:agent) { create(:agent, basic_role_in_organisations: [create(:organisation)]) }

      permissions(:show?) { it { is_expected.not_to permit(pundit_context, organisation) } }
    end
  end

  %i[edit? update? versions?].each do |action|
    describe "##{action}" do
      context "basic agent in organisation" do
        let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

        permissions(action) { it { is_expected.not_to permit(pundit_context, organisation) } }
      end

      context "admin agent in organisation" do
        let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

        permissions(action) { it { is_expected.to permit(pundit_context, organisation) } }
      end
    end
  end
end
