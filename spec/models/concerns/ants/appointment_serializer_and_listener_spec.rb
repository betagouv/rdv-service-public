# dans les stubs, Webmock reconnaît les requêtes qui ont des query params uniquement si on passe explicitement
# un with(query: hash_including({...}))

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

  describe "Création de RDV, l’usager a un numéro de pré-demande ANTS" do
    let(:organisation) { create(:organisation, verticale: :rdv_mairie) }
    let(:lieu) { create(:lieu, organisation:, name: "MDS Soleil") }
    let(:motif) { create(:motif, motif_category: create(:motif_category, :passeport)) }
    let(:user) { create(:user, ants_pre_demande_number: "A123456789", organisations: [organisation]) }
    let!(:rdv) { build(:rdv, motif:, users: [user], lieu:, organisation:, starts_at: Time.zone.parse("2020-04-20 08:00:00")) }

    it "Créé l’appointment via l’API ANTS" do
      status_stub = stub_request(:get, "#{API_URL}/status")
        .with(query: { application_ids: "A123456789" })
        .to_return(
          status: 200,
          body: { "A123456789" => { status: "validated", appointments: [] } }.to_json
        )
      create_stub = stub_request(:post, "#{API_URL}/appointments")
        .with(
          query: hash_including(
            application_id: "A123456789",
            appointment_date: "2020-04-20 08:00:00",
            meeting_point: "MDS Soleil",
            meeting_point_id: rdv.lieu.id.to_s,
            management_url: %r{http://www\.rdv-mairie-test\.localhost/users/rdvs/\d+}
          ),
          headers: ants_api_headers
        )
        .to_return(status: 200, body: { success: true }.to_json)

      perform_enqueued_jobs do
        rdv.save!
      end

      expect(status_stub).to have_been_requested.at_least_once # TODO: la requête ne devrait être faite qu’une fois
      expect(create_stub).to have_been_requested.once
    end
  end

  describe "Création de RDV, l’usager n’a pas de numéro de pré-demande ANTS" do
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

  describe "Suppression de RDV" do
    let(:organisation) { create(:organisation, verticale: :rdv_mairie) }
    let(:lieu) { create(:lieu, organisation:, name: "MDS Soleil") }
    let(:motif) { create(:motif, motif_category: create(:motif_category, :passeport)) }
    let(:user) { create(:user, ants_pre_demande_number: "A123456789", organisations: [organisation]) }
    let!(:rdv) { create(:rdv, motif:, users: [user], lieu:, organisation:, starts_at: Time.zone.parse("2020-04-20 08:00:00")) }

    it "supprime l’appointment via l’API ANTS" do
      delete_stub = stub_request(:delete, "#{API_URL}/appointments")
        .with(
          query: {
            application_id: "A123456789",
            appointment_date: "2020-04-20 08:00:00",
            meeting_point: "MDS Soleil",
            meeting_point_id: rdv.lieu.id,
          },
          headers: ants_api_headers
        )
        .to_return(status: 200, body: { rowcount: 1 }.to_json)
      status_stub = stub_request(:get, "#{API_URL}/status")
        .with(query: { application_ids: "A123456789" })
        .to_return(
          status: 200,
          body: {
            "A123456789" => {
              status: "validated",
              appointments: [
                {
                  management_url: "http://www.rdv-mairie-test.localhost/users/rdvs/#{rdv.id}",
                  meeting_point: "MDS Soleil",
                  meeting_point_id: rdv.lieu.id,
                  appointment_date: "2020-04-20 08:00:00",
                },
              ],
            },
          }.to_json
        )

      perform_enqueued_jobs do
        rdv.destroy
      end

      expect(status_stub).to have_been_requested.at_least_once # TODO: la requête ne devrait être faite qu’une fois
      expect(delete_stub).to have_been_requested.at_least_once # TODO: la requête ne devrait être faite qu’une fois
    end
  end

  describe "Annulation de RDV" do
    let(:organisation) { create(:organisation, verticale: :rdv_mairie) }
    let(:lieu) { create(:lieu, organisation:, name: "MDS Soleil") }
    let(:motif) { create(:motif, motif_category: create(:motif_category, :passeport)) }
    let(:user) { create(:user, ants_pre_demande_number: "A123456789", organisations: [organisation]) }
    let!(:rdv) { create(:rdv, motif:, users: [user], lieu:, organisation:, starts_at: Time.zone.parse("2020-04-20 08:00:00")) }

    it "supprime l’appointment via l’API ANTS" do
      status_stub = stub_request(:get, "#{API_URL}/status")
        .with(query: { application_ids: "A123456789" })
        .to_return(
          status: 200,
          body: {
            "A123456789" => {
              status: "validated",
              appointments: [
                {
                  management_url: "http://www.rdv-mairie-test.localhost/users/rdvs/#{rdv.id}",
                  meeting_point: "MDS Soleil",
                  meeting_point_id: rdv.lieu.id,
                  appointment_date: "2020-04-20 08:00:00",
                },
              ],
            },
          }.to_json
        )
      delete_stub = stub_request(:delete, "#{API_URL}/appointments")
        .with(
          query: {
            application_id: "A123456789",
            appointment_date: "2020-04-20 08:00:00",
            meeting_point: "MDS Soleil",
            meeting_point_id: rdv.lieu.id,
          },
          headers: ants_api_headers
        )
        .to_return(status: 200, body: { rowcount: 1 }.to_json)

      perform_enqueued_jobs do
        rdv.excused!
      end

      expect(status_stub).to have_been_requested.at_least_once # TODO: la requête ne devrait être faite qu’une fois
      expect(delete_stub).to have_been_requested.at_least_once # TODO: la requête ne devrait être faite qu’une fois
    end
  end

  describe "Annulation de RDV, l’API de l’ANTS renvoie un statut consumed" do
    let(:organisation) { create(:organisation, verticale: :rdv_mairie) }
    let(:lieu) { create(:lieu, organisation:, name: "MDS Soleil") }
    let(:motif) { create(:motif, motif_category: create(:motif_category, :passeport)) }
    let!(:user) { create(:user, ants_pre_demande_number: "A123456789", organisations: [organisation]) }
    let!(:rdv) { create(:rdv, motif:, users: [user], lieu:, organisation:, starts_at: Time.zone.parse("2020-04-20 08:00:00")) }

    it "ne déclenche pas la création d’un nouvel appointment via l’API ANTS" do
      status_stub = stub_request(:get, "#{API_URL}/status")
        .with(query: { application_ids: "A123456789" })
        .to_return(
          status: 200,
          body: { "A123456789" => { status: "consumed", appointments: [] } }.to_json
        )

      perform_enqueued_jobs do
        rdv.excused!
      end

      expect(status_stub).to have_been_requested.at_least_once # TODO: la requête ne devrait être faite qu’une fois
      expect(WebMock).not_to have_requested(:post, "#{API_URL}/appointments")
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
      status_stub = stub_request(:get, "#{API_URL}/status")
        .with(query: { application_ids: "A123456789" })
        .to_return(
          status: 200,
          body: {
            "A123456789" => {
              status: "validated",
              appointments: [
                {
                  management_url: "http://www.rdv-mairie-test.localhost/users/rdvs/#{rdv.id}",
                  meeting_point: "MDS Soleil",
                  meeting_point_id: rdv.lieu.id,
                  appointment_date: "2020-04-20 08:00:00",
                },
              ],
            },
          }.to_json
        )
      delete_stub = stub_request(:delete, "#{API_URL}/appointments")
        .with(query: hash_including(application_id: "A123456789"))
        .to_return(status: 200, body: { rowcount: 1 }.to_json)
      create_stub = stub_request(:post, "#{API_URL}/appointments")
        .with(
          query: {
            application_id: "A123456789",
            appointment_date: "2020-04-20 08:00:00",
            management_url: "http://www.rdv-mairie-test.localhost/users/rdvs/#{rdv.id}",
            meeting_point: "MDS Soleil",
            meeting_point_id: rdv.lieu.id,
          },
          headers: ants_api_headers
        )
        .to_return(status: 200, body: { success: true }.to_json)

      perform_enqueued_jobs do
        rdv.seen!
      end

      expect(status_stub).to have_been_requested.at_least_once # TODO: la requête ne devrait être faite qu’une fois
      expect(delete_stub).to have_been_requested.at_least_once # TODO: la requête ne devrait être faite qu’une fois
      expect(create_stub).to have_been_requested.once
    end
  end

  describe "l’usager change de numéro de pré-demande ANTS après avoir pris RDV avec un précédent numéro" do
    let(:organisation) { create(:organisation, verticale: :rdv_mairie) }
    let(:lieu) { create(:lieu, organisation:, name: "MDS Soleil") }
    let(:motif) { create(:motif, motif_category: create(:motif_category, :passeport)) }
    let!(:user) { create(:user, ants_pre_demande_number: "A123456789", organisations: [organisation]) }
    let!(:rdv) { create(:rdv, motif:, users: [user], lieu:, organisation:, starts_at: Time.zone.parse("2020-04-20 08:00:00")) }

    it "créé un nouvel appointment via l’API ANTS" do
      user.reload
      create_stub = stub_request(:post, "#{API_URL}/appointments")
        .with(query: hash_including(application_id: "AABBCCDDEE"))
        .to_return(status: 200, body: { success: true }.to_json)
      status_stub = stub_request(:get, "#{API_URL}/status")
        .with(query: { application_ids: "AABBCCDDEE" })
        .to_return(
          status: 200,
          body: { "AABBCCDDEE" => { status: "validated", appointments: [] } }.to_json
        )

      perform_enqueued_jobs do
        user.update(ants_pre_demande_number: "AABBCCDDEE")
      end

      expect(status_stub).to have_been_requested.at_least_once # TODO: la requête ne devrait être faite qu’une fois
      expect(create_stub).to have_been_requested.once
    end
  end

  describe "Le lieu change de nom" do
    let(:organisation) { create(:organisation, verticale: :rdv_mairie) }
    let(:lieu) { create(:lieu, organisation:, name: "MDS Soleil") }
    let(:motif) { create(:motif, motif_category: create(:motif_category, :passeport)) }
    let!(:user) { create(:user, ants_pre_demande_number: "A123456789", organisations: [organisation]) }
    let!(:rdv) { create(:rdv, motif:, users: [user], lieu:, organisation:, starts_at: Time.zone.parse("2020-04-20 08:00:00")) }

    it "déclenche une synchronisation avec l’ANTS" do
      lieu.reload
      create_stub = stub_request(:post, "#{API_URL}/appointments")
        .with(query: hash_including(application_id: "A123456789"))
        .to_return(status: 200, body: { success: true }.to_json)
      status_stub = stub_request(:get, "#{API_URL}/status")
        .with(query: { application_ids: "A123456789" })
        .to_return(
          status: 200,
          body: { "A123456789" => { status: "validated", appointments: [] } }.to_json
        )

      perform_enqueued_jobs do
        lieu.update(name: "Nouveau Lieu")
      end

      expect(status_stub).to have_been_requested.at_least_once # TODO: la requête ne devrait être faite qu’une fois
      expect(create_stub).to have_been_requested.once
    end
  end

  describe "un usager est retiré du RDV" do
    let(:organisation) { create(:organisation, verticale: :rdv_mairie) }
    let(:lieu) { create(:lieu, organisation:, name: "MDS Soleil") }
    let(:motif) { create(:motif, motif_category: create(:motif_category, :passeport)) }
    let!(:user) { create(:user, ants_pre_demande_number: "A123456789", organisations: [organisation]) }
    let!(:rdv) { create(:rdv, motif:, users: [user], lieu:, organisation:, starts_at: Time.zone.parse("2020-04-20 08:00:00")) }

    it "supprime l’appointment via l’API ANTS" do
      user.reload
      status_stub = stub_request(:get, "#{API_URL}/status")
        .with(query: { application_ids: "A123456789" })
        .to_return(
          status: 200,
          body: {
            "A123456789" => {
              status: "validated",
              appointments: [
                {
                  management_url: "http://www.rdv-mairie-test.localhost/users/rdvs/#{rdv.id}",
                  meeting_point: "MDS Soleil",
                  meeting_point_id: rdv.lieu.id,
                  appointment_date: "2020-04-20 08:00:00",
                },
              ],
            },
          }.to_json
        )
      delete_stub = stub_request(:delete, "#{API_URL}/appointments")
        .with(query: hash_including(application_id: "A123456789"))
        .to_return(status: 200, body: { rowcount: 1 }.to_json)

      perform_enqueued_jobs do
        user.participations.first.destroy
      end

      expect(status_stub).to have_been_requested.once
      expect(delete_stub).to have_been_requested.once
    end
  end
end
