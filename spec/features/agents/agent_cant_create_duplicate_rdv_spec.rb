# frozen_string_literal: true

RSpec.describe "Agent can't create duplicate RDV" do
  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let!(:agent) { create(:agent, service: service, basic_role_in_organisations: [organisation]) }
  let!(:motif) { create(:motif, organisation: organisation, service: service) }
  let!(:lieu) { create(:lieu, organisation: organisation) }

  context "when the user already has a RDV for the same motif on that same day" do
    let!(:marie) { create(:user, first_name: "Marie", last_name: "Curie") }

    # Setup the 3 existing RDVs: monday, tuesday and wednesday of next week at 09:00
    let!(:monday_of_next_week) { Time.zone.today.next_week.change(hour: 9) }
    let!(:tuesday_of_next_week) { monday_of_next_week + 1.day }
    let!(:wednesday_of_next_week) { tuesday_of_next_week + 1.day }
    let!(:existing_rdv_the_day_before)  { create(:rdv, organisation: organisation, users: [marie], motif: motif, starts_at: monday_of_next_week) }
    let!(:existing_rdv_same_day)        { create(:rdv, organisation: organisation, users: [marie], motif: motif, starts_at: tuesday_of_next_week) }
    let!(:existing_rdv_the_day_after)   { create(:rdv, organisation: organisation, users: [marie], motif: motif, starts_at: wednesday_of_next_week) }

    let(:route_params) do
      {
        step: 3,
        rdv: {
          starts_at: tuesday_of_next_week.change(hour: 14),
          duration_in_min: 30,
          motif_id: motif.id,
          lieu_id: lieu.id,
          agent_ids: [agent.id],
          user_ids: [marie.id],
        },
      }
    end

    before { login_as(agent, scope: :agent) }

    it "warns of existing RDV with a benign error" do
      # Try to create a new RDV on tuesday at 14:00
      visit admin_organisation_rdv_wizard_step_path(organisation, route_params)

      user_path = "/admin/organisations/#{organisation.id}/users/#{marie.id}"
      expect(page.html).to include(%(L'usager⋅e <a href="#{user_path}">Marie CURIE</a> a un autre RDV pour le même motif le même jour))
    end

    context "when the duplicate rdv has been cancelled" do
      let!(:existing_rdv_same_day) do
        create(:rdv, organisation: organisation, users: [marie], motif: motif, starts_at: tuesday_of_next_week,
                     status: Rdv::CANCELLED_STATUSES.first)
      end

      it "doesn't show a warning" do
        # Try to create a new RDV on tuesday at 14:00
        visit admin_organisation_rdv_wizard_step_path(organisation, route_params)

        user_path = "/admin/organisations/#{organisation.id}/users/#{marie.id}"
        expect(page.html).not_to include(%(L'usager⋅e <a href="#{user_path}">Marie CURIE</a> a un autre RDV pour le même motif le même jour))
      end
    end
  end

  context "when the RDV has the same motif, same lieu, same agents and users and occurs at the same time" do
    let!(:existing_rdv) { create(:rdv, organisation: organisation, starts_at: Time.zone.today.next_week.change(hour: 9)) }

    it "prevents creation with an error" do
      login_as(agent, scope: :agent)

      route_params = {
        step: 3,
        rdv: {
          starts_at: existing_rdv.starts_at,
          duration_in_min: existing_rdv.duration_in_min,
          motif_id: existing_rdv.motif.id,
          lieu_id: existing_rdv.lieu.id,
          agent_ids: existing_rdv.agents.map(&:id),
          user_ids: existing_rdv.users.map(&:id),
          ignore_benign_errors: true,
        },
      }

      visit admin_organisation_rdv_wizard_step_path(organisation, route_params)

      expect(page).to have_content("Il existe déjà un RDV au même moment, au même lieu, pour le même motif, avec les mêmes participant⋅es")
    end
  end
end
