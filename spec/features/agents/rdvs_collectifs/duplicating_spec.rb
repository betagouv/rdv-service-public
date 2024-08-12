RSpec.describe "Agent can duplicate a Rdv collectif" do
  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let!(:agent) { create(:agent, first_name: "Alain", last_name: "Tiptop", service: service, admin_role_in_organisations: [organisation]) }
  let!(:motif) { create(:motif, :collectif, service: service, organisation: organisation, name: "Atelier Collectif") }

  let(:original_rdv) do
    create(:rdv, motif: motif, organisation: organisation, agents: [agent], name: "Traitement de texte", context: "Apportez votre ordinateur")
  end

  it "allows duplicating a new rdv collectif", :js do
    login_as(agent, scope: :agent)
    visit admin_organisation_rdv_path(organisation, original_rdv)

    click_link("Dupliquer")

    fill_in "Commence à", with: I18n.l(1.week.since, format: :datetimepicker)

    click_button "Enregistrer"
    expect(page).to have_content("Le rendez-vous a été créé")

    new_rdv = Rdv.last

    expect(new_rdv).to have_attributes(
      organisation: organisation,
      duration_in_min: original_rdv.duration_in_min,
      lieu_id: original_rdv.lieu_id,
      name: original_rdv.name,
      max_participants_count: original_rdv.max_participants_count,
      context: original_rdv.context,
      motif_id: original_rdv.motif_id
    )
  end

  describe "when trying to duplicate a RDV the agent doesn't have access to" do
    let(:rdv_for_other_organisation) do
      create(:rdv, motif: motif, organisation: other_organisation, name: "Traitement de texte")
    end
    let(:other_organisation) { create(:organisation) }

    it "doesn't prefill anything" do
      login_as(agent, scope: :agent)
      expect do
        visit new_admin_organisation_rdvs_collectif_path(organisation, motif_id: motif.id, duplicated_rdv_id: rdv_for_other_organisation.id)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
