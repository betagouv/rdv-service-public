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

      context "when there is at least one plage d'ouverture that is links to an online bookable motif" do
        before { motif.plage_ouvertures << create(:plage_ouverture, organisation: organisation, agent: agent) }

        let(:plage_ouverture) { motif.plage_ouvertures.last }

        it "shows the plage d'ouverture" do
          show_request
          expect(response.body).to include(plage_ouverture.title)
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

        context "when the current organisation has an external id" do
          before { organisation.update!(external_id: "external") }

          it "shows the link to share with the external id" do
            show_request
            expect(response.body).to include(public_link_to_external_org_url(organisation.territory.departement_number, organisation.external_id))
          end
        end

        context "when the current organisation doesn't have an external id" do
          it "shows the link to share without the external id" do
            show_request
            expect(response.body).to include(public_link_to_org_url(organisation_id: organisation.id))
          end
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
