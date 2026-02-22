RSpec.describe "Step 3 of the rdv wizard" do
  let(:motif) { create(:motif, :by_phone, organisation: organisation) }
  let(:default_params) do
    {
      organisation_id: organisation.id,
      duration_in_min: 30,
      motif_id: motif.id,
      starts_at: 2.days.from_now,
      step: 3,
    }
  end
  let!(:user) do
    create(:user, organisations: [organisation], first_name: "Francis", last_name: "Factice")
  end
  let(:other_territory) { create(:territory) }
  let!(:organisation) { organisations(:default_org) }
  let(:organisation_from_other_territory) { create(:organisation, territory: other_territory) }
  let(:user_from_other_territory) do
    create(:user, organisations: [organisation_from_other_territory], first_name: "Gaston", last_name: "Bidon")
  end

  let(:agent) { create(:agent, service: motif.service, basic_role_in_organisations: [organisation]) }

  before do
    login_as(agent, scope: :agent)
  end

  describe "user" do
    context "when passing a user_id from a different territory" do
      let(:params) do
        default_params.merge(user_ids: [user_from_other_territory.id])
      end

      it "raises an error and doesn't displays the user info" do
        visit new_admin_organisation_rdv_wizard_step_path(params)
        expect(page).not_to have_content(user_from_other_territory.full_name)
        expect(page).to have_content("Vous n’avez pas les droits suffisants")
      end
    end

    context "when passing a user_id from one of the agent's territories" do
      let(:params) do
        default_params.merge(user_ids: [user.id])
      end

      it "displays the user info" do
        visit new_admin_organisation_rdv_wizard_step_path(params)
        expect(page).to have_content(user.full_name)
      end

      context "and the user belongs to many of the agent's organisations" do
        before do
          other_organisation = create(:organisation, territory: organisation.territory)
          user.organisations << other_organisation
          user.save!
        end

        it "displays the user info" do
          visit new_admin_organisation_rdv_wizard_step_path(params)
          expect(page).to have_content(user.full_name)
        end
      end
    end
  end

  describe "agent" do
    context "when passing an agent_id from a different organisation" do
      let(:other_organisation_from_same_territory) { create(:organisation, territory: organisation.territory) }
      let(:agent_from_other_organisation) do
        create(:agent, service: motif.service, basic_role_in_organisations: [other_organisation_from_same_territory])
      end
      let(:params) do
        default_params.merge(agent_ids: [agent_from_other_organisation.id])
      end

      it "raises an error and doesn't displays the agent's info" do
        visit new_admin_organisation_rdv_wizard_step_path(params)
        expect(page).not_to have_content(agent_from_other_organisation.reverse_full_name)
        expect(page).to have_content("Vous n’avez pas les droits suffisants")
      end
    end

    context "when passing an agent from the same organisation" do
      let(:agent_from_same_organisation) do
        create(:agent, service: motif.service, basic_role_in_organisations: [organisation])
      end
      let(:params) do
        default_params.merge(agent_ids: [agent_from_same_organisation.id])
      end

      it "displays the agent's info" do
        visit new_admin_organisation_rdv_wizard_step_path(params)
        expect(page).to have_content(agent_from_same_organisation.reverse_full_name)
      end

      context "and the agent is an admin of the organisation for a different service" do
        let(:admin_from_other_service) do
          create(:agent, service: create(:service), admin_role_in_organisations: [organisation])
        end
        let(:params) do
          default_params.merge(agent_ids: [admin_from_other_service.id])
        end

        it "displays the agent's info" do
          visit new_admin_organisation_rdv_wizard_step_path(params)
          expect(page).to have_content(admin_from_other_service.reverse_full_name)
        end
      end
    end
  end
end
