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

  before do
    travel_to(Time.zone.parse("01/01/2020"))
    ENV["ANTS_RDV_API_URL"] = ants_api_url
    ENV["ANTS_RDV_OPT_AUTH_TOKEN"] = "fake-token"
    stub_request(:post, %r{https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/appointments/*})
    stub_request(:delete, %r{https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/appointments/*})
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
      it "deletes appointment on ANTS" do
        perform_enqueued_jobs do
          rdv.save
          rdv.destroy
          expect(WebMock).to have_requested(
            :delete,
            "https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/appointments?application_id=A123456789&appointment_date=2020-04-20%2008:00:00&meeting_point=Lieu1"
          ).with(headers: ants_api_headers)
        end
      end
    end

    describe "after_commit on_update" do
      before { rdv.save }

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

  describe "User callbacks" do
    let(:create_appointment_stub) { stub_request(:post, %r{https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/appointments/*}) }

    before { rdv.save }

    describe "after_commit: Changing the value of ants_pre_demande_number" do
      it "triggers a sync with ANTS" do
        perform_enqueued_jobs do
          user.update!(ants_pre_demande_number: "1122334455")

          expect(create_appointment_stub).to have_been_requested.at_least_once
        end
      end
    end
  end
end
