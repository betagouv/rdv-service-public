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

  describe "#join?" do
    context "administrateur de l'espace non membre de l'organisation" do
      let!(:agent) { create(:agent, role_in_territories: [organisation.territory]) }

      permissions(:join?) { it { is_expected.to permit(pundit_context, organisation) } }
    end

    context "administrateur de l'espace déjà membre de l'organisation" do
      let!(:agent) { create(:agent, basic_role_in_organisations: [organisation], role_in_territories: [organisation.territory]) }

      permissions(:join?) { it { is_expected.not_to permit(pundit_context, organisation) } }
    end

    context "administrateur de l'espace et organisation fermée" do
      let!(:organisation) { create(:organisation, disabled_at: Time.zone.now) }
      let!(:agent) { create(:agent, role_in_territories: [organisation.territory]) }

      permissions(:join?) { it { is_expected.not_to permit(pundit_context, organisation) } }
    end

    context "agent non administrateur de l'espace" do
      let!(:agent) { create(:agent, basic_role_in_organisations: [create(:organisation, territory: organisation.territory)]) }

      permissions(:join?) { it { is_expected.not_to permit(pundit_context, organisation) } }
    end
  end
end
