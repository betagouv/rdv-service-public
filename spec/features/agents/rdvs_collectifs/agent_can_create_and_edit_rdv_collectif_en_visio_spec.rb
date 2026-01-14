RSpec.describe "Un agent peut créer et éditer un RDV collectif en visio en passant et retirant une URL de visio personnalisée", js: true do
  let(:organisation) { create(:organisation) }
  let!(:lieu) { create(:lieu, organisation:) }
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation], first_name: "Alain", last_name: "DIALO") }

  before do
    create(:motif, :collectif, name: "Atelier visio", organisation: organisation, location_type: :visio)
    stub_netsize_ok
    travel_to(Time.zone.local(2022, 3, 14))
    login_as(agent, scope: :agent)
  end

  specify do
    visit admin_organisation_rdvs_collectifs_path(organisation)
    click_link "Nouveau RDV collectif"
    click_link "Atelier visio"

    fill_in "Commence à", with: "17/3/2022 14:00"
    fill_in "Durée en minutes", with: "30"
    fill_in "Nombre de places", with: 4
    fill_in "Intitulé", with: "Déblocages administratifs"
    select("DIALO Alain", from: "rdv_agent_ids")

    # au chargement de la page, le JS devrait cacher et disabler le champ texte URL personnalisée
    expect(page).to have_selector(:element, "label", text: "URL de visioconférence", visible: false)
    expect(page).to have_selector(:field, "URL de visioconférence", visible: false, disabled: true)

    # on clique ensuite sur URL personnalisée et le champ apparait
    find("label", text: "Outil de votre choix").click
    expect(page).to have_selector(:element, "label", text: "URL de visioconférence", visible: true)
    expect(page).to have_selector(:element, "input", name: "rdv[visio_url_custom]", visible: true, disabled: false)

    # on rentre volontairement une URL invalide
    fill_in "URL de visioconférence", with: "https://test.fr/123"
    click_on "Enregistrer"
    expect(page).to have_content("L’URL doit provenir d’un des domaines suivants")

    # on vérifie que c’est le bon radio qui est coché et que le champ URL personnalisée est visible
    expect(find(:radio_button, "Outil de votre choix", visible: false)).to be_checked
    expect(find(:radio_button, "Par défaut : Webconf", visible: false)).not_to be_checked
    expect(page).to have_selector(:field, "URL de visioconférence", visible: true)

    # on rentre une URL valide
    fill_in "URL de visioconférence", with: "https://webinaire.numerique.gouv.fr/test-123"
    click_on "Enregistrer"

    # on arrive sur la liste des RDV collectifs
    expect(page).to have_content("Le rendez-vous a été créé")
    click_on "voir les détails du rendez-vous"

    # on vérifie que c’est le bon lien qui s’affiche sur le rdvs#show
    expect(find("a", text: /démarrer la visioconférence/)[:href]).to eq("https://webinaire.numerique.gouv.fr/test-123")
    click_on "Modifier"

    # on vérifie que c’est le bon radio qui est coché et que le champ URL personnalisée est visible
    expect(page).to have_selector(:radio_button, "Outil de votre choix", visible: false, checked: true)
    expect(page).to have_selector(:radio_button, "Par défaut : Webconf", visible: false, checked: false)
    expect(page).to have_selector(:field, "URL de visioconférence", visible: true)

    # on modifie pour utiliser l’outil par défaut
    # l’enjeu ici est que le radio button vide bien le champ visio_url_custom
    find("label", text: "Par défaut : Webconf").click
    click_on "Enregistrer"

    # on se retrouve sur le rdvs#show, on vérifie que le lien a été modifié
    expect(page).to have_content("Le rendez-vous a été modifié")
    expect(find("a", text: /démarrer la visioconférence/)[:href]).to match(%r{https://webconf\.numerique\.gouv\.fr})
  end
end
