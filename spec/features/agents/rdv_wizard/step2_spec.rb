RSpec.describe "Step 2 of the rdv wizard" do
  let(:motif) { create(:motif, :by_phone, organisation: organisation) }
  let(:params) do
    {
      organisation_id: organisation.id,
      duration_in_min: 30,
      motif_id: motif.id,
      starts_at: 2.days.from_now,
      step: 2,
    }
  end
  let!(:user) { create(:user, organisations: [organisation], first_name: "François", last_name: "Fictif", phone_number: "06.11.223344", email: nil, birth_date: Date.new(1990, 1, 1)) }
  let!(:user_from_other_organisation) { create(:user, organisations: [other_organisation], first_name: "Francis", last_name: "Factice", phone_number_formatted: nil, email: "francis@factice.cool") }
  let(:territory) { create(:territory) }
  let(:organisation) { create(:organisation, territory: territory) }
  let(:other_organisation) { create(:organisation, territory: territory) }
  let(:agent) { create(:agent, service: motif.service, basic_role_in_organisations: [organisation]) }
  let(:cni_motif_category) { create(:motif_category, name: Api::Ants::EditorController::CNI_MOTIF_CATEGORY_NAME) }

  before do
    create(:agent_territorial_access_right, agent: agent, territory: territory)

    login_as(agent, scope: :agent)
    visit new_admin_organisation_rdv_wizard_step_path(params)
  end

  it "allows searching for users", js: true do
    # Click on the search field
    find(".collapse-add-user-selection .select2-selection").click

    find(".select2-search__field").send_keys("Franc")

    expect(page).to have_content("FICTIF François - 01/01/1990 - 06 11 22 33 44")
    expect(page).to have_content("Usagers des autres organisations")
    expect(page).to have_content("FACTICE Francis")

    find(".select2-search__field").send_keys("o") # Search is "Franco"

    expect(page).to have_content("FICTIF François")
    expect(page).not_to have_content("Usagers des autres organisations")
    expect(page).not_to have_content("FACTICE Francis")

    find(".select2-search__field").send_keys(:backspace)

    find(".select2-search__field").send_keys("i") # Search is "Franci"

    expect(page).not_to have_content("FICTIF François")
    expect(page).to have_content("Usagers des autres organisations")
    expect(page).to have_content("FACTICE Francis")

    find(".select2-search__field").send_keys(:backspace)
    find(".select2-search__field").send_keys("k")

    expect(page).to have_content("Aucun résultat")
  end

  describe "ANTS pre-demande field" do
    let(:motif) do
      create(:motif, name: "Carte d'identité", organisation: organisation, restriction_for_rdv: nil, motif_category: cni_motif_category, default_duration_in_min: 25)
    end

    let(:ants_pre_demande_number) { "1122334455" }

    before { click_link "Créer un usager" }

    context "ants_pre_demander number is validated and has no appointment declared yet" do
      before do
        stub_request(:get, %r{https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/status}).to_return(
          status: 200,
          body: {
            ants_pre_demande_number => {
              status: "validated",
              appointments: [],
            },
          }.to_json
        )
      end

      it "creates user with no warning" do
        fill_in :user_first_name, with: "Marco"
        fill_in :user_last_name, with: "Lebreton"
        fill_in :user_ants_pre_demande_number, with: ants_pre_demande_number
        click_button "Créer"
        expect(page).not_to have_content("déjà utilisé")
        expect(page).to have_content "LEBRETON Marco"

        expect(User.last).to have_attributes(
          first_name: "Marco",
          last_name: "Lebreton",
          ants_pre_demande_number: ants_pre_demande_number
        )
      end
    end

    context "ants_pre_demander number is validated but already has appointments" do
      before do
        stub_request(:get, %r{https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/status}).to_return(
          status: 200,
          body: {
            ants_pre_demande_number => {
              status: "validated",
              appointments: [
                {
                  management_url: "https://gerer-rdv.com",
                  meeting_point: "Mairie de Sannois",
                  appointment_date: "2023-04-03T08:45:00",
                },
              ],
            },
          }.to_json
        )
      end

      it "displays a warning but allows user creation" do
        fill_in :user_first_name, with: "Marco"
        fill_in :user_last_name, with: "Lebreton"
        fill_in :user_ants_pre_demande_number, with: ants_pre_demande_number
        click_button "Créer"
        expect(page).to have_content(
          "Ce numéro de pré-demande ANTS est déjà utilisé pour un RDV auprès de Mairie de Sannois. Veuillez annuler ce RDV avant d'en prendre un nouveau"
        )
        click_button("Confirmer en ignorant les avertissements")
        expect(page).to have_content "LEBRETON Marco"

        expect(User.last).to have_attributes(
          first_name: "Marco",
          last_name: "Lebreton",
          ants_pre_demande_number: ants_pre_demande_number
        )
      end
    end

    context "ants_pre_demander number is consumed (dossier déjà envoyé et instruit en préfecture)" do
      before do
        stub_request(:get, %r{https://int.api-coordination.rendezvouspasseport.ants.gouv.fr/api/status}).to_return(
          status: 200,
          body: {
            ants_pre_demande_number => {
              status: "consumed",
              appointments: [],
            },
          }.to_json
        )
      end

      it "prevents agent from creating the user / RDV" do
        fill_in :user_first_name, with: "Marco"
        fill_in :user_last_name, with: "Lebreton"
        fill_in :user_ants_pre_demande_number, with: ants_pre_demande_number
        click_button "Créer"
        expect(page).to have_content("Ce numéro de pré-demande ANTS correspond à un dossier déjà instruit")
        expect(page).not_to have_content("Confirmer en ignorant les avertissements")
      end
    end

    context "the rdv motif is not related to ANTS, but there is another motif for ANTS in the organisation" do
      let(:motif) do
        create(:motif, name: "Permis de construire", organisation: organisation, motif_category: nil)
      end

      before do
        create(:motif, name: "Carte d'identité", organisation: organisation, restriction_for_rdv: nil, motif_category: cni_motif_category, default_duration_in_min: 25)
      end

      it "doesn't ask for the ants number", js: true do
        expect(page).to have_content("Prénom")
        expect(page).not_to have_content("ANTS")
      end
    end
  end
end
