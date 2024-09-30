API_URL = "https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api".freeze

RSpec.describe Ants::AppointmentSerializerAndListener do
  include_context "rdv_mairie_api_authentication"

  let(:organisation) { create(:organisation, verticale: :rdv_mairie) }
  let(:user) { create(:user, ants_pre_demande_number: "A123456789", organisations: [organisation]) }
  let(:lieu) { create(:lieu, organisation: organisation, name: "MDS Soleil") }
  let(:motif_passeport) { create(:motif, motif_category: create(:motif_category, :passeport)) }
  let(:rdv) { build(:rdv, motif: motif_passeport, users: [user], lieu: lieu, organisation: organisation, starts_at: Time.zone.parse("2020-04-20 08:00:00")) }
  let(:ants_api_headers) do
    {
      "Accept" => "application/json",
      "Expect" => "",
      "User-Agent" => "Typhoeus - https://github.com/typhoeus/typhoeus",
      "X-Rdv-Opt-Auth-Token" => "fake-token",
    }
  end

  def stub_ants_status_with_appointments
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
  end

  describe "RDV callbacks" do
    describe "after_commit on_create" do
      it "creates appointment on ANTS" do
        stub_ants_status("A123456789")
        stub_ants_create("A123456789")

        perform_enqueued_jobs do
          rdv.save!
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
        let(:user) { create(:user, ants_pre_demande_number: "", organisations: [organisation]) }

        it "doesn't send a request to the appointment ANTS api" do
          perform_enqueued_jobs do
            rdv.save!

            expect(WebMock).not_to have_requested(:any, %r{\.ants\.gouv\.fr/api})
          end
        end

        context "and the rdv is cancelled" do
          before { rdv.status = "excused" }

          it "doesn't send a request to the appointment ANTS api" do
            perform_enqueued_jobs do
              rdv.save!

              expect(WebMock).not_to have_requested(:any, %r{\.ants\.gouv\.fr/api})
            end
          end
        end
      end
    end

    describe "after_commit on_destroy" do
      it "deletes appointment on ANTS" do
        rdv.save!
        stub_ants_delete("A123456789")
        stub_ants_status_with_appointments

        perform_enqueued_jobs do
          rdv.destroy
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
    end

    describe "after_commit on_update" do
      before do
        rdv.save!
        stub_ants_status_with_appointments
      end

      describe "Rdv is cancelled" do
        it "deletes appointment on ANTS" do
          perform_enqueued_jobs do
            stub_ants_delete("A123456789")
            rdv.excused!

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
      end

      describe "Rdv is re-activated after cancellation" do
        before do
          rdv.excused!
        end

        it "creates appointment" do
          perform_enqueued_jobs do
            stub_ants_delete("A123456789")
            stub_ants_create("A123456789")
            rdv.seen!
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
  end

  describe "User callbacks" do
    let!(:create_appointment_stub) do
      stub_ants_create("AABBCCDDEE")
    end

    describe "after_commit: Changing the value of ants_pre_demande_number" do
      it "creates appointment with new ants_pre_demande_number" do
        rdv.save!
        user.reload

        perform_enqueued_jobs do
          stub_ants_status("AABBCCDDEE")
          user.update(ants_pre_demande_number: "AABBCCDDEE")

          expect(create_appointment_stub).to have_been_requested.at_least_once
        end
      end
    end
  end

  describe "Lieu callbacks" do
    let!(:create_appointment_stub) do
      stub_ants_create("A123456789")
    end

    before do
      rdv.save!
      lieu.reload
    end

    describe "after_commit: Changing the name of the lieu" do
      it "triggers a sync with ANTS" do
        perform_enqueued_jobs do
          stub_ants_status("A123456789")
          lieu.update(name: "Nouveau Lieu")

          expect(create_appointment_stub).to have_been_requested.at_least_once
        end
      end
    end
  end

  describe "Participation callbacks" do
    before do
      stub_ants_status("A123456789")
      rdv.save!
      user.reload
      rdv.participations.reload
      stub_ants_status_with_appointments
    end

    describe "after_commit: Removing user participation" do
      it "deletes appointment" do
        perform_enqueued_jobs do
          stub_ants_delete("A123456789")
          user.participations.first.destroy
        end
      end
    end
  end

  context "ANTS application ID is consumed" do
    before do
      stub_request(:get, "#{API_URL}/status")
        .with(query: hash_including(application_ids: user.ants_pre_demande_number))
        .to_return(
          status: 200,
          body: {
            user.ants_pre_demande_number => {
              status: "consumed",
              appointments: [],
            },
          }.to_json
        )
    end

    let(:rdv) do
      create(
        :rdv,
        motif: motif_passeport,
        users: [user],
        lieu: lieu,
        organisation: organisation,
        starts_at: Time.zone.parse("2020-04-20 08:00:00")
      )
    end

    describe "after_commit on_update" do
      describe "Rdv is cancelled" do
        it "does not sync with ANTS" do
          perform_enqueued_jobs do
            rdv.excused!

            expect(WebMock).not_to have_requested(
              :post,
              "#{API_URL}/appointments"
            ).with(headers: ants_api_headers)
          end
        end
      end
    end
  end
end
