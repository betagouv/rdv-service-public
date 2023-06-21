# frozen_string_literal: true

RSpec.describe Ants::EventSerializerAndListener do
  let(:organisation) { create(:organisation, verticale: :rdv_mairie) }
  let(:user) { create(:user, ants_pre_demande_number: "A123456789", organisations: [organisation]) }
  let(:lieu) { create(:lieu, organisation: organisation, name: "Lieu1") }
  let(:rdv) { build(:rdv, users: [user], lieu: lieu, organisation: organisation, starts_at: Time.zone.parse("2020-04-20 08:00:00")) }
  let(:ants_api_url) { "https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api" }
  let(:ants_api_headers) do
    {
      "Accept" => "application/json",
      "Expect" => "",
      "User-Agent" => "Typhoeus - https://github.com/typhoeus/typhoeus",
      "X-Rdv-Opt-Auth-Token" => "fake-token",
    }
  end

  def stub_status_endpoint
    stub_request(:get, %r{https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/status}).to_return(
      status: 200,
      body: {
        user.ants_pre_demande_number => {
          appointments: [
            {
              management_url: Rails.application.routes.url_helpers.rdvs_short_url(rdv, host: organisation.domain.host_name),
              meeting_point: rdv.lieu.name,
              appointment_date: rdv.starts_at.strftime("%Y-%m-%d %H:%M:%S"),
            },
          ],
        },
      }.to_json
    )
  end

  before do
    travel_to(Time.zone.parse("01/01/2020"))
    ENV["ANTS_RDV_API_URL"] = ants_api_url
    ENV["ANTS_RDV_OPT_AUTH_TOKEN"] = "fake-token"
    stub_request(:post, %r{https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/appointments/*}).to_return(status: 200, body: "{}".to_json)
    stub_request(:delete, %r{https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/appointments/*})
    stub_request(:get, %r{https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/status})
  end

  describe "RDV callbacks" do
    describe "after_commit on_create" do
      it "creates appointment on ANTS" do
        perform_enqueued_jobs do
          rdv.save
          expect(WebMock).to have_requested(
            :post,
            "https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/appointments?application_id=A123456789&appointment_date=2020-04-20%2008:00:00&management_url=http://www.rdv-mairie-test.localhost/r.#{rdv.id}&meeting_point=Lieu1"
          ).with(headers: ants_api_headers)
        end
      end
    end

    describe "after_commit on_destroy" do
      before do
        rdv.save

        stub_status_endpoint
      end

      it "deletes appointment on ANTS" do
        perform_enqueued_jobs do
          rdv.destroy
          expect(WebMock).to have_requested(
            :delete,
            "https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/appointments?application_id=A123456789&appointment_date=2020-04-20%2008:00:00&meeting_point=Lieu1"
          ).with(headers: ants_api_headers)
        end
      end
    end

    describe "after_commit on_update" do
      before do
        rdv.save

        stub_status_endpoint
      end

      describe "Rdv is cancelled" do
        it "deletes appointment on ANTS" do
          perform_enqueued_jobs do
            rdv.excused!

            expect(WebMock).to have_requested(
              :delete,
              "https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/appointments?application_id=A123456789&appointment_date=2020-04-20%2008:00:00&meeting_point=Lieu1"
            ).with(headers: ants_api_headers)
          end
        end
      end

      describe "Rdv is re-activated after cancellation" do
        before do
          rdv.excused!
        end

        it "creates appointment" do
          perform_enqueued_jobs do
            rdv.seen!
            expect(WebMock).to have_requested(
              :post,
              "https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/appointments?application_id=A123456789&appointment_date=2020-04-20%2008:00:00&management_url=http://www.rdv-mairie-test.localhost/r.#{rdv.id}&meeting_point=Lieu1"
            ).with(headers: ants_api_headers)
          end
        end
      end
    end
  end

  pending "User callbacks" do
    let(:create_appointment_stub) { stub_request(:post, %r{https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/appointments/*}) }

    before { rdv.save }

    describe "after_commit: Changing the value of ants_pre_demande_number" do
      it "triggers a sync with ANTS" do
        perform_enqueued_jobs do
          user.update(ants_pre_demande_number: "AABBCCDDEE")

          expect(create_appointment_stub).to have_been_requested.at_least_once
        end
      end
    end
  end

  pending "Lieu callbacks" do
    let(:create_appointment_stub) { stub_request(:post, %r{https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/appointments/*}) }

    before { rdv.save }

    describe "after_commit: Changing the name of the lieu" do
      it "triggers a sync with ANTS" do
        perform_enqueued_jobs do
          lieu.update(name: "Nouveau Lieu")

          expect(create_appointment_stub).to have_been_requested.at_least_once
        end
      end
    end
  end
end
