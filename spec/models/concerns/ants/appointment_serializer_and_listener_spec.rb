API_URL = "https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api".freeze

RSpec.describe Ants::AppointmentSerializerAndListener do
  include_context "rdv_mairie_api_authentication"

  let(:ants_api_headers) do
    {
      "Accept" => "application/json",
      "Expect" => "",
      "User-Agent" => "Typhoeus - https://github.com/typhoeus/typhoeus",
      "X-Rdv-Opt-Auth-Token" => "fake-token",
    }
  end

  describe "RDV callbacks" do
    describe "after_commit on_create" do
      context "l’usager a un numéro de pré-demande ANTS" do
        let(:organisation) { create(:organisation, verticale: :rdv_mairie) }
        let(:lieu) { create(:lieu, organisation:, name: "MDS Soleil") }
        let(:motif) { create(:motif, motif_category: create(:motif_category, :passeport)) }
        let(:user) { create(:user, ants_pre_demande_number: "A123456789", organisations: [organisation]) }
        let(:rdv) { build(:rdv, motif:, users: [user], lieu:, organisation:, starts_at: Time.zone.parse("2020-04-20 08:00:00")) }

        it "creates appointment on ANTS" do
          stub_ants_status("A123456789", status: "validated", appointments: [])
          stub_ants_create("A123456789")
          perform_enqueued_jobs do
            rdv.save!
          end
          expect(WebMock).to have_requested(:post, "#{API_URL}/appointments")
            .with(
              query: {
                application_id: "A123456789",
                appointment_date: "2020-04-20 08:00:00",
                management_url: "http://www.rdv-mairie-test.localhost/users/rdvs/#{rdv.id}",
                meeting_point: "MDS Soleil",
                meeting_point_id: rdv.lieu.id,
              },
              headers: ants_api_headers
            ).at_least_once
        end
      end

      context "when the user is created by an agent who didn't fill in the pre_demande_number" do
        let(:organisation) { create(:organisation, verticale: :rdv_mairie) }
        let(:lieu) { create(:lieu, organisation:, name: "MDS Soleil") }
        let(:motif) { create(:motif, motif_category: create(:motif_category, :passeport)) }
        let(:user) { create(:user, ants_pre_demande_number: "", organisations: [organisation]) }
        let(:rdv) { build(:rdv, motif:, users: [user], lieu:, organisation:, starts_at: Time.zone.parse("2020-04-20 08:00:00")) }

        it "doesn't send a request to the appointment ANTS api" do
          perform_enqueued_jobs do
            rdv.save!
          end
          expect(WebMock).not_to have_requested(:any, %r{\.ants\.gouv\.fr/api})
        end

        context "and the rdv is cancelled" do
          before { rdv.status = "excused" }

          it "doesn't send a request to the appointment ANTS api" do
            perform_enqueued_jobs do
              rdv.save!
            end
            expect(WebMock).not_to have_requested(:any, %r{\.ants\.gouv\.fr/api})
          end
        end
      end
    end

    describe "after_commit on_destroy" do
      let(:organisation) { create(:organisation, verticale: :rdv_mairie) }
      let(:lieu) { create(:lieu, organisation:, name: "MDS Soleil") }
      let(:motif) { create(:motif, motif_category: create(:motif_category, :passeport)) }
      let(:user) { create(:user, ants_pre_demande_number: "A123456789", organisations: [organisation]) }
      let!(:rdv) { create(:rdv, motif:, users: [user], lieu:, organisation:, starts_at: Time.zone.parse("2020-04-20 08:00:00")) }

      it "deletes appointment on ANTS" do
        stub_ants_delete("A123456789")
        stub_ants_status(
          "A123456789",
          appointments: [
            {
              management_url: "http://www.rdv-mairie-test.localhost/users/rdvs/#{rdv.id}",
              meeting_point: "MDS Soleil",
              meeting_point_id: rdv.lieu.id,
              appointment_date: "2020-04-20 08:00:00",
            },
          ]
        )
        perform_enqueued_jobs do
          rdv.destroy
        end
        expect(WebMock).to have_requested(:delete, "#{API_URL}/appointments")
          .with(
            query: {
              application_id: "A123456789",
              appointment_date: "2020-04-20 08:00:00",
              meeting_point: "MDS Soleil",
              meeting_point_id: rdv.lieu.id,
            },
            headers: ants_api_headers
          ).at_least_once
      end
    end

    describe "after_commit on_update" do
      describe "Rdv is cancelled" do
        let(:organisation) { create(:organisation, verticale: :rdv_mairie) }
        let(:lieu) { create(:lieu, organisation:, name: "MDS Soleil") }
        let(:motif) { create(:motif, motif_category: create(:motif_category, :passeport)) }
        let(:user) { create(:user, ants_pre_demande_number: "A123456789", organisations: [organisation]) }
        let!(:rdv) { create(:rdv, motif:, users: [user], lieu:, organisation:, starts_at: Time.zone.parse("2020-04-20 08:00:00")) }

        it "deletes appointment on ANTS" do
          stub_ants_status(
            "A123456789",
            appointments: [
              {
                management_url: "http://www.rdv-mairie-test.localhost/users/rdvs/#{rdv.id}",
                meeting_point: "MDS Soleil",
                meeting_point_id: rdv.lieu.id,
                appointment_date: "2020-04-20 08:00:00",
              },
            ]
          )
          stub_ants_delete("A123456789")
          perform_enqueued_jobs do
            rdv.excused!
          end
          expect(WebMock).to have_requested(:delete, "#{API_URL}/appointments")
            .with(
              query: {
                application_id: "A123456789",
                appointment_date: "2020-04-20 08:00:00",
                meeting_point: "MDS Soleil",
                meeting_point_id: rdv.lieu.id,
              },
              headers: ants_api_headers
            ).at_least_once
        end
      end

      describe "Rdv is re-activated after cancellation" do
        let(:organisation) { create(:organisation, verticale: :rdv_mairie) }
        let(:lieu) { create(:lieu, organisation:, name: "MDS Soleil") }
        let(:motif) { create(:motif, motif_category: create(:motif_category, :passeport)) }
        let(:user) { create(:user, ants_pre_demande_number: "A123456789", organisations: [organisation]) }
        let!(:rdv) { create(:rdv, motif:, users: [user], lieu:, organisation:, starts_at: Time.zone.parse("2020-04-20 08:00:00")) }

        before { rdv.excused! }

        it "creates appointment" do
          stub_ants_status(
            "A123456789",
            appointments: [
              {
                management_url: "http://www.rdv-mairie-test.localhost/users/rdvs/#{rdv.id}",
                meeting_point: "MDS Soleil",
                meeting_point_id: rdv.lieu.id,
                appointment_date: "2020-04-20 08:00:00",
              },
            ]
          )
          stub_ants_delete("A123456789")
          stub_ants_create("A123456789")
          perform_enqueued_jobs do
            rdv.seen!
          end
          expect(WebMock).to have_requested(:post, "#{API_URL}/appointments")
            .with(
              query: {
                application_id: "A123456789",
                appointment_date: "2020-04-20 08:00:00",
                management_url: "http://www.rdv-mairie-test.localhost/users/rdvs/#{rdv.id}",
                meeting_point: "MDS Soleil",
                meeting_point_id: rdv.lieu.id,
              },
              headers: ants_api_headers
            ).at_least_once
        end
      end
    end
  end

  describe "User callbacks" do
    describe "after_commit: Changing the value of ants_pre_demande_number" do
      let(:organisation) { create(:organisation, verticale: :rdv_mairie) }
      let(:lieu) { create(:lieu, organisation:, name: "MDS Soleil") }
      let(:motif) { create(:motif, motif_category: create(:motif_category, :passeport)) }
      let!(:user) { create(:user, ants_pre_demande_number: "A123456789", organisations: [organisation]) }
      let!(:rdv) { create(:rdv, motif:, users: [user], lieu:, organisation:, starts_at: Time.zone.parse("2020-04-20 08:00:00")) }

      it "creates appointment with new ants_pre_demande_number" do
        user.reload
        create_appointment_stub = stub_ants_create("AABBCCDDEE")
        stub_ants_status("AABBCCDDEE", status: "validated", appointments: [])
        perform_enqueued_jobs do
          user.update(ants_pre_demande_number: "AABBCCDDEE")
        end
        expect(create_appointment_stub).to have_been_requested.at_least_once
      end
    end
  end

  describe "Lieu callbacks" do
    describe "after_commit: Changing the name of the lieu" do
      let(:organisation) { create(:organisation, verticale: :rdv_mairie) }
      let(:lieu) { create(:lieu, organisation:, name: "MDS Soleil") }
      let(:motif) { create(:motif, motif_category: create(:motif_category, :passeport)) }
      let!(:user) { create(:user, ants_pre_demande_number: "A123456789", organisations: [organisation]) }
      let!(:rdv) { create(:rdv, motif:, users: [user], lieu:, organisation:, starts_at: Time.zone.parse("2020-04-20 08:00:00")) }

      it "triggers a sync with ANTS" do
        lieu.reload
        create_appointment_stub = stub_ants_create("A123456789")
        stub_ants_status("A123456789", status: "validated", appointments: [])
        perform_enqueued_jobs do
          lieu.update(name: "Nouveau Lieu")
        end
        expect(create_appointment_stub).to have_been_requested.at_least_once
      end
    end
  end

  describe "Participation callbacks" do
    describe "after_commit: Removing user participation" do
      let(:organisation) { create(:organisation, verticale: :rdv_mairie) }
      let(:lieu) { create(:lieu, organisation:, name: "MDS Soleil") }
      let(:motif) { create(:motif, motif_category: create(:motif_category, :passeport)) }
      let!(:user) { create(:user, ants_pre_demande_number: "A123456789", organisations: [organisation]) }
      let!(:rdv) { create(:rdv, motif:, users: [user], lieu:, organisation:, starts_at: Time.zone.parse("2020-04-20 08:00:00")) }

      it "deletes appointment" do
        user.reload
        stub_ants_status("A123456789", status: "validated", appointments: [])
        stub_ants_status(
          "A123456789",
          appointments: [
            {
              management_url: "http://www.rdv-mairie-test.localhost/users/rdvs/#{rdv.id}",
              meeting_point: "MDS Soleil",
              meeting_point_id: rdv.lieu.id,
              appointment_date: "2020-04-20 08:00:00",
            },
          ]
        )
        stub_ants_delete("A123456789")
        perform_enqueued_jobs do
          user.participations.first.destroy
        end
      end
    end
  end

  context "ANTS application ID is consumed" do
    describe "after_commit on_update" do
      describe "Rdv is cancelled" do
        let(:organisation) { create(:organisation, verticale: :rdv_mairie) }
        let(:lieu) { create(:lieu, organisation:, name: "MDS Soleil") }
        let(:motif) { create(:motif, motif_category: create(:motif_category, :passeport)) }
        let!(:user) { create(:user, ants_pre_demande_number: "A123456789", organisations: [organisation]) }
        let!(:rdv) { create(:rdv, motif:, users: [user], lieu:, organisation:, starts_at: Time.zone.parse("2020-04-20 08:00:00")) }

        it "does not sync with ANTS" do
          stub_ants_status("A123456789", status: "consumed", appointments: [])
          perform_enqueued_jobs do
            rdv.excused!
          end
          expect(WebMock).not_to have_requested(:post, "#{API_URL}/appointments").with(headers: ants_api_headers)
        end
      end
    end
  end
end
