RSpec.describe "Admin::UserInWaitingRoomController", type: :request do
  include Rails.application.routes.url_helpers

  describe "POST /admin/organisations/:organisation_id/rdvs/:rdv_id/user_in_waiting_room" do
    it "render JS" do
      territory = create(:territory, enable_waiting_room_mail_field: true, enable_waiting_room_color_field: true)
      organisation = create(:organisation, territory: territory)
      agent = create(:agent, basic_role_in_organisations: [organisation])
      rdv = create(:rdv, agents: [agent], organisation: organisation)
      sign_in agent

      post admin_organisation_rdv_user_in_waiting_room_path(rdv.organisation, rdv, format: :js)
      expect(response.body).to include("waiting_room_button")
    end

    it "send email" do
      territory = create(:territory, enable_waiting_room_mail_field: true, enable_waiting_room_color_field: false)
      organisation = create(:organisation, territory: territory)
      agent = create(:agent, basic_role_in_organisations: [organisation])
      rdv = create(:rdv, agents: [agent], organisation: organisation)
      sign_in agent

      expect do
        post admin_organisation_rdv_user_in_waiting_room_path(rdv.organisation, rdv, format: :js)
      end.to have_enqueued_mail(Agents::WaitingRoomMailer, :user_in_waiting_room).with(params: { agent: agent, rdv: rdv }, args: [])

      rdv.reload
      expect(rdv.user_in_waiting_room?).to be(true)
    end

    it "add redis key for this RDV" do
      territory = create(:territory, enable_waiting_room_mail_field: false, enable_waiting_room_color_field: true)
      organisation = create(:organisation, territory: territory)
      agent = create(:agent, basic_role_in_organisations: [organisation])
      rdv = create(:rdv, agents: [agent], organisation: organisation)
      sign_in agent

      post admin_organisation_rdv_user_in_waiting_room_path(rdv.organisation, rdv, format: :js)

      rdv.reload
      expect(rdv.user_in_waiting_room?).to be(true)
    end
  end

  describe "waiting action visibility" do
    it "hide waiting room action when no waiting room notifications configured" do
      now = Time.zone.parse("2022-12-05 10:00")
      travel_to(now)
      territory = create(:territory, enable_waiting_room_mail_field: false, enable_waiting_room_color_field: false)
      organisation = create(:organisation, territory: territory)
      agent = create(:agent, basic_role_in_organisations: [organisation])
      rdv = create(:rdv, agents: [agent], organisation: organisation, starts_at: now + 2.hours)
      sign_in agent

      get admin_organisation_rdv_path(organisation, rdv)
      expect(response.body).not_to include("Salle d&#39;attente")
    end

    it "hide waiting room action when rdv is not for today" do
      now = Time.zone.parse("2022-12-05 10:00")
      travel_to(now)
      territory = create(:territory, enable_waiting_room_mail_field: true, enable_waiting_room_color_field: true)
      organisation = create(:organisation, territory: territory)
      agent = create(:agent, basic_role_in_organisations: [organisation])
      rdv = create(:rdv, agents: [agent], organisation: organisation, starts_at: now + 4.days)
      sign_in agent

      get admin_organisation_rdv_path(organisation, rdv)
      expect(response.body).not_to include("Salle d&#39;attente")
    end

    it "hide waiting room action when rdv is for today with an other statuts than unknown" do
      now = Time.zone.parse("2022-12-05 10:00")
      travel_to(now)
      territory = create(:territory, enable_waiting_room_mail_field: true, enable_waiting_room_color_field: true)
      organisation = create(:organisation, territory: territory)
      agent = create(:agent, basic_role_in_organisations: [organisation])
      rdv = create(:rdv, agents: [agent], organisation: organisation, starts_at: now + 4.hours, status: "revoked")
      sign_in agent

      get admin_organisation_rdv_path(organisation, rdv)
      expect(response.body).not_to include("Salle d&#39;attente")
    end

    it "show user in waiting room button when email configure" do
      now = Time.zone.parse("2022-12-05 10:00")
      travel_to(now)
      territory = create(:territory, enable_waiting_room_mail_field: true, enable_waiting_room_color_field: false)
      organisation = create(:organisation, territory: territory)
      agent = create(:agent, basic_role_in_organisations: [organisation])
      rdv = create(:rdv, agents: [agent], organisation: organisation, starts_at: now + 4.hours, status: "unknown")
      sign_in agent

      get admin_organisation_rdv_path(organisation, rdv)
      expect(response.body).to include("Salle d&#39;attente")
    end

    it "show user in waiting room button when color configure" do
      now = Time.zone.parse("2022-12-05 10:00")
      travel_to(now)
      territory = create(:territory, enable_waiting_room_mail_field: false, enable_waiting_room_color_field: true)
      organisation = create(:organisation, territory: territory)
      agent = create(:agent, basic_role_in_organisations: [organisation])
      rdv = create(:rdv, agents: [agent], organisation: organisation, starts_at: now + 4.hours, status: "unknown")
      sign_in agent

      get admin_organisation_rdv_path(organisation, rdv)
      expect(response.body).to include("Salle d&#39;attente")
    end
  end
end
