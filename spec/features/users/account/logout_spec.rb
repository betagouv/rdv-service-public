RSpec.describe "Déconnexion" do
  let(:user) { create(:user) }
  let(:motif) { create(:motif, bookable_by: :everyone, organisation: organisation) }
  let(:organisation) { create(:organisation) }
  let(:lieu) { create(:lieu, organisation: organisation) }

  let!(:plage_ouverture) { create(:plage_ouverture, :weekdays, first_day: 1.month.from_now, motifs: [motif], lieu: lieu, organisation: organisation) }

  it "fonctionne après une prise de rdv" do
    visit public_link_to_org_path(organisation_id: organisation.public_link_id, org_slug: organisation.slug)
    click_on motif.name
    click_on lieu.name
    first(:link, "11:00").click

    login_via_6_digit_code(user.email)

    click_button("Continuer")
    click_button("Continuer")
    click_link("Confirmer mon RDV")
    expect(page).to have_content("Votre RDV")

    click_on "Déconnexion"

    visit public_link_to_org_path(organisation_id: organisation.public_link_id, org_slug: organisation.slug)
    click_on motif.name
    click_on lieu.name
    first(:link, "11:00").click

    # On vérifie que les infos de l'utilisateur n'ont pas été gardées dans la session
    expect(page).to have_content("Vous devez vous connecter ou vous inscrire pour continuer.")

    expect(page.body).not_to include(user.first_name) # Le prénom est dans un input, donc on utilise cette méthode plutôt qu'un expect(page).to have_content
  end
end
