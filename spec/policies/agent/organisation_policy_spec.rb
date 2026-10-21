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

  describe Agent::OrganisationPolicy::JoinableScope do
    subject(:resolved) { described_class.new(agent, Organisation).resolve }

    let!(:other_organisation_in_territory) { create(:organisation, territory: organisation.territory) }
    let!(:closed_organisation_in_territory) { create(:organisation, territory: organisation.territory, disabled_at: Time.zone.now) }
    let!(:organisation_in_other_territory) { create(:organisation) }

    context "administrateur de l'espace" do
      let(:agent) { create(:agent, basic_role_in_organisations: [organisation], role_in_territories: [organisation.territory]) }

      it "liste les organisations ouvertes de l'espace dont il n'est pas membre" do
        expect(resolved).to contain_exactly(other_organisation_in_territory)
      end
    end

    context "agent ayant des droits d'accès à l'espace sans en être administrateur" do
      let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }

      before { create(:agent_territorial_access_right, agent:, territory: organisation.territory, allow_to_manage_teams: true) }

      it "ne liste aucune organisation" do
        expect(resolved).to be_empty
      end
    end
  end
end
