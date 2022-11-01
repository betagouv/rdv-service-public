# frozen_string_literal: true

RSpec.describe "Admin::Organisations::OnlineBookings", type: :request do
  include Rails.application.routes.url_helpers

  let(:organisation) { create(:organisation) }
  let(:agent) { create(:agent, :cnfs, admin_role_in_organisations: [organisation]) }

  before { sign_in agent }

  describe "GET /admin/organisations/:organisation_id/online_booking" do
    subject(:show_request) { get admin_organisation_online_booking_path(organisation) }

    it "is successful" do
      show_request
      expect(response).to be_successful
    end

    it { expect(show_request).to render_template(:show) }

    describe "motifs" do
      context "when there is at least one motif that can be booked online" do
        let!(:motif) { create(:motif, organisation: organisation, service: agent.service, reservable_online: true) }

        it "shows the motif" do
          show_request
          expect(response.body).to include(motif.name)
        end
      end

      context "when there is no motifs that can be booked online" do
        it "shows a message about how to create motifs" do
          show_request
          expect(response.body).to include("Aucun de vos motifs n'est ouvert à la réservation en ligne")
        end
      end
    end

    describe "plages d'ouverture" do
      let(:motif) { create(:motif, organisation: organisation, service: agent.service, reservable_online: true) }

      context "when there is at least one plage d'ouverture that is related to an online bookable motif" do
        let!(:matching_plage_ouverture) { create(:plage_ouverture, organisation: organisation, agent: agent, motifs: [motif]) }

        it "shows the plage d'ouverture" do
          show_request
          expect(response.body).to include(matching_plage_ouverture.title)
        end

        it "filters out the plage d'ouverture from other organisations" do
          other_organisation = create(:organisation)
          other_motif = create(:motif, organisation: other_organisation, service: agent.service, reservable_online: true)
          agent = create(:agent, :cnfs, admin_role_in_organisations: [organisation, other_organisation])
          unmatching_plage_ouverture = create(:plage_ouverture, agent: agent, motifs: [motif, other_motif], organisation: other_organisation)

          show_request
          expect(response.body).to include(matching_plage_ouverture.title)
          expect(response.body).not_to include(unmatching_plage_ouverture.title)
        end

        it "filters out the plage d'ouverture in the past" do
          unmatching_plage_ouverture = create(:plage_ouverture, organisation: organisation, agent: agent, motifs: [motif], first_day: 1.day.ago)

          show_request
          expect(response.body).to include(matching_plage_ouverture.title)
          expect(response.body).not_to include(unmatching_plage_ouverture.title)
        end
      end

      context "when there is no plage d'ouverture linked to an online bookable motif" do
        it "shows a message about how to create a plage d'ouverture" do
          show_request
          expect(response.body).to include("aucune n'est liée à un motif")
        end
      end
    end

    describe "booking link" do
      context "when online bookable motifs and related plage d'ouverture are missing" do
        it "shows a message about the link that is inaccessible" do
          show_request
          expect(response.body).to include("Dès que les motifs et les plages d'ouverture seront paramétrés pour la réservation en ligne")
        end
      end

      context "when there is at least one online bookable motif and a linked plage d'ouverture" do
        before do
          motif = create(:motif, organisation: organisation, service: agent.service, reservable_online: true)
          motif.plage_ouvertures << create(:plage_ouverture, organisation: organisation, agent: agent)
        end

        it "shows a message about the link that can be used" do
          show_request
          expect(response.body).to include("Copiez et partagez-le à vos usagers pour leur permettre de réserver en ligne.")
        end

        it "shows the public link to share" do
          show_request
          expect(response.body).to include(public_link_to_org_url(organisation_id: organisation.id))
        end
      end
    end

    describe "edge cases" do
      context "when the current agent is not a conseiller numerique" do
        let(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

        it "redirects to the authenticated agent root page" do
          show_request
          expect(response).to redirect_to(authenticated_agent_root_path)
        end
      end
    end
  end
end
