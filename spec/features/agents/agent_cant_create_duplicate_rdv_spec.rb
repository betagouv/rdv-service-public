# frozen_string_literal: true

RSpec.describe "Agent can't create duplicate RDV" do
  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let!(:agent) { create(:agent, service: service, basic_role_in_organisations: [organisation]) }

  context "when the user already has a RDV for the same motif on that same day" do
    let!(:motif) { create(:motif, organisation: organisation, service: service) }
    let!(:lieu) { create(:lieu, organisation: organisation) }
    let!(:user) { create(:user, first_name: "Marie", last_name: "Curie") }

    # Setup the 3 existing RDVs: monday, tuesday and wednesday of next week at 09:00
    let!(:monday_of_next_week) { Time.zone.today.next_week.change(hour: 9) }
    let!(:tuesday_of_next_week) { monday_of_next_week + 1.day }
    let!(:wednesday_of_next_week) { tuesday_of_next_week + 1.day }
    let!(:existing_rdv_the_day_before) { create(:rdv, users: [user], motif: motif, starts_at: monday_of_next_week) }
    let!(:existing_rdv_same_day) { create(:rdv, users: [user], motif: motif, starts_at: tuesday_of_next_week) }
    let!(:existing_rdv_the_day_after) { create(:rdv, users: [user], motif: motif, starts_at: wednesday_of_next_week) }

    # Try to create a new RDV on tuesday at 14:00
    let(:rdv) { build(:rdv, users: [user], motif: motif, starts_at: tuesday_of_next_week.change(hour: 14)) }

    it "warns of existing RDV" do
      login_as(agent, scope: :agent)

      route_params = {
        step: 3,
        rdv: {
          starts_at: tuesday_of_next_week.beginning_of_day,
          duration_in_min: 30,
          service_id: motif.service_id,
          motif_id: motif.id,
          lieu_id: lieu.id,
          agent_ids: [agent.id],
          user_ids: [user.id],
        },
      }

      visit admin_organisation_rdv_wizard_step_path(organisation, route_params)

      user_path = "/admin/organisations/#{organisation.id}/users/#{user.id}"
      expect(page.html).to include(%(L'usager⋅e <a href="#{user_path}">Marie CURIE</a> a un autre RDV pour le même motif le même jour))
    end
  end
end
