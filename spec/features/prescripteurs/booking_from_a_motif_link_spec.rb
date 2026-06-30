RSpec.describe "Prescription depuis un lien de motif" do
  let(:motif) do
    create(:motif, bookable_by: :agents_and_prescripteurs)
  end
  let(:agent) do
    create(:agent, admin_role_in_organisations: [motif.organisation])
  end

  before { login_as(agent, scope: :agent) }

  it "permet de faire de la prescription depuis le lien affiché dans les détails du motif" do
    visit admin_organisation_online_booking_motif_path(motif.organisation, motif)
    expect(page).to have_content("Lien de réservation pour les prescripteurs")

    find(".rdv-align-items-baseline > a[target=_blank]").click
    expect(page).to have_content("Prenez rendez-vous en ligne") # On se fait rediriger vers la prise de rendez-vous en ligne

    # Le lien a bien le paramètre de prescription
    expect(page.current_url).to end_with("/prendre_rdv?departement=01&motif_id=#{motif.id}&prescripteur=1&public_link_organisation_id=#{motif.organisation_id}")
  end
end
