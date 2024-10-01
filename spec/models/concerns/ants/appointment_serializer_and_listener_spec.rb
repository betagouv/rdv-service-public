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
        let!(:rdv) { build(:rdv, motif:, users: [user], lieu:, organisation:, starts_at: Time.zone.parse("2020-04-20 08:00:00")) }

        it "créé l’appointment via l’API ANTS" do
          stub_ants_status("A123456789", status: "validated", appointments: [])
          stub_request(:post, "#{API_URL}/appointments")
            .with(query: hash_including(application_id: "A123456789")) # Webmock ne répond pas à la requête POST avec des query params sans cette ligne
            .to_return(status: 200, body: { success: true }.to_json)

          perform_enqueued_jobs do
            rdv.save!
          end

          expect(WebMock).to have_requested(:post, "#{API_URL}/appointments")
            .with(
              query: hash_including(
                application_id: "A123456789",
                appointment_date: "2020-04-20 08:00:00",
                meeting_point: "MDS Soleil",
                meeting_point_id: rdv.lieu.id.to_s,
                management_url: "http://www.rdv-mairie-test.localhost/users/rdvs/#{rdv.id}"
              ),
              headers: ants_api_headers
            )
            .once
        end
      end

      context "l’usager n’a pas de numéro de pré-demande ANTS" do
        let(:organisation) { create(:organisation, verticale: :rdv_mairie) }
        let(:lieu) { create(:lieu, organisation:, name: "MDS Soleil") }
        let(:motif) { create(:motif, motif_category: create(:motif_category, :passeport)) }
        let(:user) { create(:user, ants_pre_demande_number: "", organisations: [organisation]) }
        let(:rdv) { build(:rdv, motif:, users: [user], lieu:, organisation:, starts_at: Time.zone.parse("2020-04-20 08:00:00")) }

        it "n’appelle pas du tout l’API ANTS" do
          perform_enqueued_jobs do
            rdv.save!
          end
          expect(WebMock).not_to have_requested(:any, %r{\.ants\.gouv\.fr/api})
        end

        context "et le RDV est annulé" do
          before { rdv.status = "excused" }

          it "n’appelle pas du tout l’API ANTS" do
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

      it "supprime l’appointment via l’API ANTS" do
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
      describe "le RDV est annulé" do
        let(:organisation) { create(:organisation, verticale: :rdv_mairie) }
        let(:lieu) { create(:lieu, organisation:, name: "MDS Soleil") }
        let(:motif) { create(:motif, motif_category: create(:motif_category, :passeport)) }
        let(:user) { create(:user, ants_pre_demande_number: "A123456789", organisations: [organisation]) }
        let!(:rdv) { create(:rdv, motif:, users: [user], lieu:, organisation:, starts_at: Time.zone.parse("2020-04-20 08:00:00")) }

        it "supprime l’appointment via l’API ANTS" do
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

      describe "le RDV est marqué comme vu alors qu’il avait été annulé" do
        let(:organisation) { create(:organisation, verticale: :rdv_mairie) }
        let(:lieu) { create(:lieu, organisation:, name: "MDS Soleil") }
        let(:motif) { create(:motif, motif_category: create(:motif_category, :passeport)) }
        let(:user) { create(:user, ants_pre_demande_number: "A123456789", organisations: [organisation]) }
        let!(:rdv) { create(:rdv, motif:, users: [user], lieu:, organisation:, starts_at: Time.zone.parse("2020-04-20 08:00:00")) }

        before { rdv.excused! }

        it "créé l’appointment via l’API ANTS" do
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
    describe "after_commit: l’usager change de numéro de pré-demande ANTS" do
      let(:organisation) { create(:organisation, verticale: :rdv_mairie) }
      let(:lieu) { create(:lieu, organisation:, name: "MDS Soleil") }
      let(:motif) { create(:motif, motif_category: create(:motif_category, :passeport)) }
      let!(:user) { create(:user, ants_pre_demande_number: "A123456789", organisations: [organisation]) }
      let!(:rdv) { create(:rdv, motif:, users: [user], lieu:, organisation:, starts_at: Time.zone.parse("2020-04-20 08:00:00")) }

      it "créé un nouvel appointment via l’API ANTS" do
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
    describe "after_commit: le lieu change de nom" do
      let(:organisation) { create(:organisation, verticale: :rdv_mairie) }
      let(:lieu) { create(:lieu, organisation:, name: "MDS Soleil") }
      let(:motif) { create(:motif, motif_category: create(:motif_category, :passeport)) }
      let!(:user) { create(:user, ants_pre_demande_number: "A123456789", organisations: [organisation]) }
      let!(:rdv) { create(:rdv, motif:, users: [user], lieu:, organisation:, starts_at: Time.zone.parse("2020-04-20 08:00:00")) }

      it "déclenche une synchronisation avec l’ANTS" do
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
    describe "after_commit: un usager est retiré du RDV" do
      let(:organisation) { create(:organisation, verticale: :rdv_mairie) }
      let(:lieu) { create(:lieu, organisation:, name: "MDS Soleil") }
      let(:motif) { create(:motif, motif_category: create(:motif_category, :passeport)) }
      let!(:user) { create(:user, ants_pre_demande_number: "A123456789", organisations: [organisation]) }
      let!(:rdv) { create(:rdv, motif:, users: [user], lieu:, organisation:, starts_at: Time.zone.parse("2020-04-20 08:00:00")) }

      it "supprime l’appointment via l’API ANTS" do
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
      describe "le RDV est annulé" do
        let(:organisation) { create(:organisation, verticale: :rdv_mairie) }
        let(:lieu) { create(:lieu, organisation:, name: "MDS Soleil") }
        let(:motif) { create(:motif, motif_category: create(:motif_category, :passeport)) }
        let!(:user) { create(:user, ants_pre_demande_number: "A123456789", organisations: [organisation]) }
        let!(:rdv) { create(:rdv, motif:, users: [user], lieu:, organisation:, starts_at: Time.zone.parse("2020-04-20 08:00:00")) }

        it "ne déclenche pas la création d’un nouvel appointment via l’API ANTS" do
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
