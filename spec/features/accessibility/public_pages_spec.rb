RSpec.describe "public pages", js: true do
  it "accessibility_path page is accessible" do
    expect_page_to_be_axe_clean(accessibility_path)
  end

  it "contact_path page is accessible" do
    expect_page_to_be_axe_clean(contact_path)
  end

  it "accueil_mds_path page is accessible" do
    visit "http://www.rdv-solidarites-test.localhost/accueil_mds"
    # This path now redirects to the generic /presentation_agent page
    expect(page).to have_current_path("/presentation_agent")
    expect(page).to be_axe_clean
  end

  it "presentation for aide numérique page is accessible" do
    visit "http://www.rdv-aide-numerique-test.localhost/presentation_agent"
    expect(page).to have_current_path("/presentation_agent")
    # TODO: make it accessible
    # expect(page).to be_axe_clean
  end

  it "home page for RDV Mairie is accessible" do
    visit "http://www.rdv-mairie-test.localhost/"
    expect(page).to have_current_path("/")
    # TODO: investiguer si les résultats de ce test d'accessibilité sont valides
    # axe indique que l'attribut aria-labelledby n'est pas valide, alors qu'il est documenté par mozilla
    # et utilisé par le dsfr.
    # expect(page).to be_axe_clean
  end

  it "presentation page for RDV Mairie is accessible" do
    visit "http://www.rdv-mairie-test.localhost/presentation_agent"
    expect(page).to have_current_path("/presentation_agent")
    # TODO: make it accessible
    # expect(page).to be_axe_clean
  end

  it "mds_path page is accessible" do
    expect_page_to_be_axe_clean(mds_path)
  end

  context "prendre RDV" do
    # prendre_rdv est la root_path pour le public non connecté
    #

    it "is accessible" do
      territory = create(:territory, departement_number: "75")
      service = create(:service)
      organisation = create(:organisation, territory: territory)
      motif = create(:motif, service: service, organisation: organisation)
      lieu = create(:lieu, organisation: organisation)
      create(:plage_ouverture, motifs: [motif], lieu: lieu)

      path = prendre_rdv_path(city_code: "75_119",
                              departement: "75",
                              latitude: "48.887148",
                              longitude: "2.38748",
                              street_ban_id: "75119_4903",
                              address: "152 Avenue Jean Jaurès Paris 75019 Paris")
      expect_page_to_be_axe_clean(path)
    end

    describe "with available slots" do
      # Nécessite de préciser le département pour le moment,
      # à cause de la recherche par sectorisation (?)
      let(:territory) { create(:territory, departement_number: "75") }
      let(:organisation) { create(:organisation, territory: territory) }
      let(:lieu) { create(:lieu, organisation: organisation) }
      # Double motif pour s'assurer de passer par la page de choix des motifs
      let(:motif) { create(:motif, organisation: organisation, name: "Consultation prénatale") }
      let(:autre_motif) { create(:motif, organisation: organisation, service: motif.service) }
      let(:autre_service_motif) { create(:motif, organisation: organisation, service: create(:service)) }

      let!(:po_pour_motif) { create(:plage_ouverture, motifs: [motif], lieu: lieu) }
      let!(:po_pour_autre_motif) { create(:plage_ouverture, motifs: [autre_motif], lieu: lieu) }
      let!(:po_pour_autre_service_motif) { create(:plage_ouverture, motifs: [autre_service_motif], lieu: lieu) }

      it "root path is accessible" do
        expect_page_to_be_axe_clean(root_path)
      end

      it "root path with a city_code page is accessible" do
        path = prendre_rdv_path(
          departement: 75,
          city_code: 75_056,
          street_ban_id: nil,
          latitude: 48.859,
          longitude: 2.347,
          address: "Paris 75001"
        )
        visit path
        expect(page).to have_content("Sélectionnez le service avec qui vous voulez prendre un RDV")

        expect_page_to_be_axe_clean(path)
      end

      it "root path with a city_code and a service page is accessible" do
        path = prendre_rdv_path(
          departement: 75,
          city_code: 75_056,
          street_ban_id: nil,
          latitude: 48.859,
          longitude: 2.347,
          address: "Paris 75001",
          service_id: motif.service_id
        )
        visit path
        expect(page).to have_content("Sélectionnez le motif de votre RDV")

        expect_page_to_be_axe_clean(path)
      end

      it "root path with a city_code and motif page is accessible" do
        path = prendre_rdv_path(
          motif_name_with_location_type: "consultation_prenatale-public_office",
          address: "Paris 75001",
          city_code: 75_056,
          departement: 75,
          latitude: 48.859,
          longitude: 2.347,
          street_ban_id: nil
        )
        visit path
        expect(page).to have_content("Sélectionnez un lieu de RDV")

        expect_page_to_be_axe_clean(path)
      end

      it "root path with a city_code, motif and lieu page is accessible" do
        path = prendre_rdv_path(
          motif_name_with_location_type: "consultation_prenatale-public_office",
          address: "Paris 75001",
          city_code: 75_056,
          departement: 75,
          latitude: 48.859,
          longitude: 2.347,
          street_ban_id: nil,
          lieu_id: lieu.id,
          date: Time.zone.now
        )

        visit path
        expect(page).to have_content("dimanche")

        expect_page_to_be_axe_clean(path)
      end

      context "when invited" do
        let!(:user) { create(:user) }
        let!(:invitation_token) { user.set_rdv_invitation_token! }

        it "root path with a city_code and a service page is accessible" do
          path = prendre_rdv_path(
            departement: 75,
            city_code: 75_056,
            street_ban_id: nil,
            latitude: 48.859,
            longitude: 2.347,
            address: "Paris 75001",
            service_id: motif.service_id
          )
          visit path
          expect(page).to have_content("Sélectionnez le motif de votre RDV")

          expect_page_to_be_axe_clean(path)
        end

        it "root path with a city_code and motif page is accessible" do
          path = prendre_rdv_path(
            motif_name_with_location_type: "consultation_prenatale-public_office",
            address: "Paris 75001",
            city_code: 75_056,
            departement: 75,
            latitude: 48.859,
            longitude: 2.347,
            street_ban_id: nil
          )
          visit path
          expect(page).to have_content("Sélectionnez un lieu de RDV")

          expect_page_to_be_axe_clean(path)
        end

        it "root path with a city_code, motif and lieu page is accessible" do
          path = prendre_rdv_path(
            motif_name_with_location_type: "consultation_prenatale-public_office",
            address: "Paris 75001",
            city_code: 75_056,
            departement: 75,
            latitude: 48.859,
            longitude: 2.347,
            street_ban_id: nil,
            lieu_id: lieu.id,
            date: Time.zone.now
          )

          visit path
          expect(page).to have_content("dimanche")

          expect_page_to_be_axe_clean(path)
        end
      end
    end
  end
end
