# frozen_string_literal: true

describe "User can search rdv on rdv mairie" do
  let(:now) { Time.zone.parse("2021-12-13 8:00") }

  def json_response
    JSON.parse(page.html)
  end

  before do
    default_url_options[:host] = "http://www.rdv-mairie-test.localhost"
  end

  around do |example|
    previous_auth_token = ENV["ANTS_API_AUTH_TOKEN"]
    ENV["ANTS_API_AUTH_TOKEN"] = ""

    example.run

    ENV["ANTS_API_AUTH_TOKEN"] = previous_auth_token
  end

  before do
    travel_to(now)
    create(:plage_ouverture, :no_recurrence, first_day: now, motifs: [motif], lieu: lieu, organisation: organisation, start_time: Tod::TimeOfDay(9), end_time: Tod::TimeOfDay.new(10))
  end

  describe "default" do
    let!(:territory95) { create(:territory, departement_number: "95") }
    let!(:organisation) { create(:organisation, :with_contact, territory: territory95, verticale: :rdv_mairie) }
    let(:service) { create(:service) }
    let!(:motif) { create(:motif, name: "Passeport", bookable_publicly: true, organisation: organisation, restriction_for_rdv: nil, service: service) }
    let!(:lieu) { create(:lieu, organisation: organisation, name: "Mairie de Sannois", address: "15 Place du Général Leclerc, Sannois, 95110") }

    it "default" do
      lieux_ids = fetch_lieux_ids_from_ants
      creneaux_url = fetch_time_slots_from_ants(lieux_ids)
      visit_public_creneaux_link(creneaux_url)
    end
  end

  private

  def fetch_lieux_ids_from_ants
    visit api_ants_getManagedMeetingPoints_url
    lieux_ids = json_response.map { |lieu_data| lieu_data["id"] }

    expect(lieux_ids).to eq([lieu.id.to_s])

    lieux_ids
  end

  def fetch_time_slots_from_ants(lieux_ids)
    visit api_ants_availableTimeSlots_url(
      meeting_point_ids: lieux_ids,
      start_date: Date.yesterday,
      end_date: Date.tomorrow
    )

    time = Time.zone.now.change(hour: 9, min: 0o0)

    expect(json_response).to eq(
      {
        lieu.id.to_s => [
          {
            "datetime" => time.strftime("%Y-%m-%dT%H:%MZ"),
            "callback_url" => creneaux_url(starts_at: time.strftime("%Y-%m-%d %H:%M"), lieu_id: lieu.id, motif_id: motif.id),
          },
        ],
      }
    )

    json_response[lieu.id.to_s].first["callback_url"]
  end

  def visit_public_creneaux_link(creneaux_url)
    visit creneaux_url

    expect(page).to have_current_path("/users/sign_in")
    expect(page).to have_content("Vous devez vous connecter ou vous inscrire pour continuer")
    expect(page).to have_content("Motif : Passeport")
    expect(page).to have_content("Lieu : Mairie de Sannois (15 Place du Général Leclerc, Sannois, 95110)")
    expect(page).to have_content("Date du rendez-vous : lundi 13 décembre 2021 à 09h00 (45 minutes)")
  end
end
