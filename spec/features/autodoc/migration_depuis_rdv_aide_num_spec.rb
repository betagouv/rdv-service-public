RSpec.describe "Migration depuis RDV Aide Numérique vers RDV Service Public", js: true do
  around { |example| perform_enqueued_jobs { example.run } }

  # Pour simplifier les test, on crée deux agents sur la même instance
  let(:organisation_rdv_aide_num) do
    create(:organisation, name: "France Service de Montreuil",
                          phone_number: "01 22 33 44 55",
                          website: "www.montreuil.fr/france-service",
                          email: "contact@exemple.montreuil.fr")
  end
  let!(:agent_rdv_aide_num) do
    create(:agent, first_name: "Camille", last_name: "Clavier", admin_role_in_organisations: [organisation_rdv_aide_num])
  end

  let!(:collegue) do
    create(:agent, first_name: "Francis", last_name: "Factice", basic_role_in_organisations: [organisation_rdv_aide_num])
  end
  let!(:lieu) { create(:lieu, organisation: organisation_rdv_aide_num) }
  let!(:motif) { create(:motif, organisation: organisation_rdv_aide_num) }
  let!(:motif_collectif) { create(:motif, :collectif, organisation: organisation_rdv_aide_num) }

  let!(:users) do
    create_list(:user, 3, organisations: [organisation_rdv_aide_num])
  end

  let!(:future_rdv) do
    create(:rdv, agents: [collegue], users: [users.last], starts_at: 2.weeks.from_now, motif:, lieu:, organisation: organisation_rdv_aide_num)
  end
  let!(:future_rdv_collectif) do
    create(:rdv, agents: [collegue], users: [], starts_at: 2.weeks.from_now, motif: motif_collectif, lieu:, organisation: organisation_rdv_aide_num)
  end
  let!(:old_rdv) do
    create(:rdv, agents: [collegue], users: [users.last], starts_at: 2.weeks.ago, motif:, lieu:, organisation: organisation_rdv_aide_num)
  end

  let!(:absence) { create(:absence, :no_recurrence, agent: agent_rdv_aide_num) }
  let!(:recurrent_absence) { create(:absence, :weekly_on_monday, agent: agent_rdv_aide_num) }
  let!(:recurrent_absence_with_end_date) { create(:absence, :weekly_on_monday_until_next_month, agent: agent_rdv_aide_num) }
  let!(:plage_ouverture) do
    create(:plage_ouverture, :weekly_on_monday_until_next_month, agent: agent_rdv_aide_num, organisation: organisation_rdv_aide_num, lieu: lieu, motifs: [motif])
  end

  let!(:absence_du_collegue) { create(:absence, :no_recurrence, agent: collegue) }

  let!(:agent_rdv_sp) do
    create(:agent, first_name: "Camille", last_name: "Clavier", password: "c0rrecThorse!", admin_role_in_organisations: [])
  end

  let!(:oauth_application) do
    application = OauthApplication.new(
      name: "RDV Aide Numérique",
      uid: "fake-app-id",
      redirect_uri: "http://www.rdv-aide-numerique-test.localhost/omniauth/rdvservicepublic/callback",
      logo_base64: "",
      default_service: create(:service)
    )

    application.secret_strategy.store_secret(application, :secret, "fake-app-secret")
    application.save!

    application
  end

  stub_env_for_proconnect
  stub_env_with(
    RDV_SERVICE_PUBLIC_OAUTH_APP_ID: "fake-app-id",
    RDV_SERVICE_PUBLIC_OAUTH_APP_SECRET: "fake-app-secret",
    RDV_SERVICE_PUBLIC_OAUTH_BASE_URL: "http://localhost:#{Capybara.server_port}"
  )

  specify do
    doc = Autodoc.start_scenario("Migration depuis RDV Aide Numérique vers RDV Service Public", self, category: "5) RDV Aide Numérique")

    doc.start_section("Migration")
    doc.add_text(<<~TEXT
      Dans un premier temps, cette fonctionnalité n'est accessible que en ayant directement l'url.
      On va la communiquer aux beta testeurs, et on pourra ensuite la rendre accessible depuis le menu des paramètres.
    TEXT
                )

    login_as(agent_rdv_aide_num, scope: :agent)
    visit "http://www.rdv-aide-numerique-test.localhost/agents/instance_exports"

    Capybara.page.current_window.resize_to(1280, 1200)

    doc.add_screenshot(page,
                       text: "J'ouvre la page à https://www.rdv-aide-numerique.fr/agents/instance_exports, puis je clique sur le bouton pour commencer",
                       wait_for: "Migration vers RDV Service Public")

    Capybara.page.current_window.resize_to(1280, 720)

    click_on "Commencer", match: :first

    doc.add_screenshot(page,
                       text: "On m'explique l'étape suivante. Je clique sur le bouton de connexion",
                       wait_for: "Pour commencer")

    # On triche un peu pour simuler la connexion à RDV SP
    visit "http://#{Domain::RDV_SERVICE_PUBLIC.host_name}/agents/sign_in"

    doc.add_screenshot(page,
                       text: "Je me connecte sur RDV Service Public",
                       wait_for: "Connexion agent à RDV Service Public")

    # Et on triche à nouveau pour faire le callback d'oauth
    # en imitant le code de Admin::InstanceExportsController#oauth_callback

    rdv_sp_token = create(:access_token, resource_owner_id: agent_rdv_sp.id, application: oauth_application)

    instance_export = InstanceExport.create!(
      agent: agent_rdv_aide_num,
      api_token: rdv_sp_token.plaintext_token,
      refresh_token: rdv_sp_token.refresh_token,
      source_organisation_id: organisation_rdv_aide_num
    )

    visit "http://www.rdv-aide-numerique-test.localhost/admin/organisations/#{organisation_rdv_aide_num.id}/instance_exports/#{instance_export.id}/edit"

    doc.add_screenshot(page,
                       text: "Je suis redirigé vers RDV Aide Numérique, je clique sur Copier les données",
                       wait_for: "Ces données vont être copiées")

    click_on "Copier les données"

    doc.add_screenshot(page,
                       text: "La migration est réussie. Mes usagers sont maintenant disponibles sur RDV Service Public",
                       wait_for: "Vos données ont été copiées dans RDV Service Public")

    created_organisation = Organisation.last
    expect(created_organisation.external_references.last.external_id).to eq organisation_rdv_aide_num.id.to_s

    expect(created_organisation.territory.enable_context_field).to be true

    expect(created_organisation).to have_attributes(
      name: "France Service de Montreuil",
      phone_number: "01 22 33 44 55",
      website: "www.montreuil.fr/france-service",
      email: "contact@exemple.montreuil.fr",
      verticale: "rdv_mairie"
    )

    expect(created_organisation.users.last.notification_email).to be_present

    expect(created_organisation.agents.count).to eq 2

    created_lieu = created_organisation.lieux.sole
    expect(created_lieu).to have_attributes(name: lieu.name)
    expect(created_lieu.external_references.last).to have_attributes(external_id: lieu.id.to_s)

    created_motif = created_organisation.motifs.individuel.sole
    expect(created_motif).to have_attributes(name: motif.name)

    created_organisation.users.last

    # On importe les anciens rendez-vous
    created_rdv = created_organisation.rdvs.last
    expect(created_rdv).to have_attributes(
      lieu: created_lieu,
      motif: created_motif,
      agents: created_organisation.agents.where(email: collegue.email)
    )
    expect(created_rdv.external_references.last).to have_attributes(
      external_id: old_rdv.id.to_s,
      external_url: "http://www.rdv-aide-numerique-test.localhost/admin/organisations/#{organisation_rdv_aide_num.id}/rdvs/#{old_rdv.id}"
    )

    expect(created_rdv.users.first.full_name).to eq old_rdv.users.first.full_name

    # On crée des absences qui permettent de retrouver les rendez-vous sur l'ancienne instance
    absence_representing_rdv = collegue.absences.find_by(title: "RDV avec #{future_rdv.users.first.full_name} (sur RDV Aide Numérique)")
    expect(absence_representing_rdv.starts_at).to be_within(1.minute).of(future_rdv.starts_at)
    expect(absence_representing_rdv.external_references.last.external_url).to eq "http://www.rdv-aide-numerique-test.localhost/admin/organisations/#{organisation_rdv_aide_num.id}/rdvs/#{future_rdv.id}"

    # On crée aussi des copies des absences futures
    expect(agent_rdv_sp.absences.exceptionnelles.first.starts_at).to eq absence.starts_at

    new_absence_without_end_date = agent_rdv_sp.absences.regulieres.where(recurrence_ends_at: nil).first
    expect(Montrose::Recurrence.dump(new_absence_without_end_date.recurrence)).to eq Montrose::Recurrence.dump(recurrent_absence.recurrence)
    expect(new_absence_without_end_date.recurrence_ends_at).to eq recurrent_absence.recurrence_ends_at

    new_absence_with_end_date = agent_rdv_sp.absences.regulieres.where.not(recurrence_ends_at: nil).first
    expect(Montrose::Recurrence.dump(new_absence_with_end_date.recurrence)).to eq Montrose::Recurrence.dump(recurrent_absence_with_end_date.recurrence)
    expect(new_absence_with_end_date.recurrence_ends_at).to eq recurrent_absence_with_end_date.recurrence_ends_at

    new_plage_ouverture = agent_rdv_sp.plage_ouvertures.last
    expect(Montrose::Recurrence.dump(new_plage_ouverture.recurrence)).to eq Montrose::Recurrence.dump(plage_ouverture.recurrence)

    # Les external_ids permettent de configurer les associations correctement
    expect(new_plage_ouverture).to have_attributes(
      lieu_id: created_lieu.id,
      motif_ids: [created_motif.id]
    )

    # Les absences du collègue sont copiées
    copied_absence = collegue.reload.absences.joins(:external_references)
      .where(external_references: { external_id: "absence:#{absence_du_collegue.id}" })
    expect(copied_absence).to be_present

    login_as(agent_rdv_sp, scope: :agent)
    visit "http://www.rdv-service-public-test.localhost/admin/organisations/#{created_organisation.id}/agents"

    doc.add_screenshot(page,
                       text: "En se connectant sur RDV Service Public, on constate que les agents ont bien été créés.",
                       wait_for: collegue.email)
  end
end
