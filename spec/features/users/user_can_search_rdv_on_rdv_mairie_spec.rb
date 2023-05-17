# frozen_string_literal: true

describe "User can search rdv on rdv mairie" do
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
    travel_to(Time.zone.now)
    create(:plage_ouverture, :daily, first_day: Time.zone.today, motifs: [motif], lieu: lieu, organisation: organisation, start_time: Tod::TimeOfDay(9), end_time: Tod::TimeOfDay(10))
  end

  describe "default" do
    let!(:territory92) { create(:territory, departement_number: "92") }
    let!(:organisation) { create(:organisation, :with_contact, territory: territory92, verticale: :rdv_mairie) }
    let(:service) { create(:service) }
    let!(:motif) { create(:motif, name: "Vaccination", bookable_publicly: true, organisation: organisation, restriction_for_rdv: nil, service: service) }
    let!(:lieu) { create(:lieu, organisation: organisation) }

    it "default" do
      lieux_ids = fetch_lieux_ids_from_ants
      creneaux_url = fetch_time_slots_from_ants(lieux_ids)
      visit_creneaux_url(creneaux_url)
      pick_creneau
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

  def visit_creneaux_url(creneaux_url)
    visit creneaux_url

    expect(page).to have_current_path(
      prendre_rdv_path(
        lieu_id: lieu.id,
        motif_name_with_location_type: motif.name_with_location_type,
        departement: organisation.departement_number,
        date: Time.zone.now.change(hour: 9, min: 0o0).strftime("%Y-%m-%d %H:%M")
      )
    )

    expect(page).to have_selector("h1", text: "Prenez rendez-vous avec votre mairie")
    expect(page).to have_selector("h3", text: "Sélectionnez un créneau")
  end

  def pick_creneau
    first(:link, "09:00").click

    expect(page).to have_current_path("/users/sign_in")
    expect(page).to have_content("Vous devez vous connecter ou vous inscrire pour continuer")
  end
end
