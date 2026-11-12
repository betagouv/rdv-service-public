RSpec.describe "Un agent peut supprimer un RDV" do
  let(:organisation) { create(:organisation) }
  let(:agent) { create(:agent, first_name: "Alice", last_name: "Martin", admin_role_in_organisations: [organisation]) }
  let(:other_agent) { create(:agent, email: "collegue@example.com", basic_role_in_organisations: [organisation]) }
  let(:motif) { create(:motif, organisation: organisation, name: "Consultation spéciale") }
  let(:user) { create(:user) }
  let(:users) { [user] }
  let!(:rdv) do
    create(:rdv, organisation: organisation, motif: motif, agents: [agent, other_agent], users: users,
                 starts_at: Time.zone.local(2026, 12, 15, 10, 30), duration_in_min: 30)
  end

  before do
    travel_to(Time.zone.local(2026, 12, 1, 9, 0))
    login_as(agent, scope: :agent)
  end

  def supprimer_le_rdv
    visit admin_organisation_rdv_path(organisation, rdv)
    click_link "Supprimer"
    expect(page).to have_content("Le rendez-vous a été supprimé.")
    expect(Rdv.where(id: rdv.id)).to be_empty
    perform_enqueued_jobs
  end

  it "supprime le RDV et notifie les autres agents avec le motif, la date, l'auteur et un lien vers l'usager" do
    supprimer_le_rdv

    open_email "collegue@example.com"
    expect(current_email.subject).to include("supprimé")
    expect(current_email.body).to include("Consultation spéciale")
    expect(current_email.body).to include("15 décembre")
    expect(current_email.body).to include("10h30")
    expect(current_email.body).to include("par #{agent.full_name}")
    expect(current_email.body).to include(admin_organisation_user_url(organisation, user, host: other_agent.domain.host_name))
    expect(current_email.body).not_to include(user.full_name)
  end

  it "ne notifie pas l'agent qui supprime le RDV, même avec toutes les notifications activées, mais seulement son collègue" do
    agent.update!(rdv_notifications_level: "all")
    supprimer_le_rdv

    expect(ActionMailer::Base.deliveries.flat_map(&:to)).to eq(["collegue@example.com"])
  end

  context "quand le RDV a plusieurs usagers" do
    let(:other_user) { create(:user) }
    let(:users) { [user, other_user] }

    it "liste dans l'email un lien vers la fiche de chaque usager" do
      supprimer_le_rdv

      open_email "collegue@example.com"
      host = other_agent.domain.host_name
      expect(current_email.body).to include("Consultation spéciale")
      expect(current_email.body).to include(admin_organisation_user_url(organisation, user, host: host))
      expect(current_email.body).to include(admin_organisation_user_url(organisation, other_user, host: host))
      expect(current_email.body).not_to include(user.full_name)
      expect(current_email.body).not_to include(other_user.full_name)
    end
  end
end
