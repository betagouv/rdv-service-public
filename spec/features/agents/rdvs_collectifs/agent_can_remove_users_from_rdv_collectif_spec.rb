RSpec.describe "Un agent peut retirer des usagers d’un RDV Collectif", js: true do
  let(:now) { Time.zone.parse("2025-11-26 10:00") }

  let!(:organisation) { create(:organisation) }
  let!(:service) { create(:service) }
  let!(:agent_noe) { create(:agent, first_name: "Noé", last_name: "Jacquet", email: "noe@service.fr", service:, admin_role_in_organisations: [organisation]) }
  let!(:agent_bouba) { create(:agent, first_name: "Bouba", email: "bouba@service.fr", service:, basic_role_in_organisations: [organisation]) }
  let!(:motif) { create(:motif, :collectif, service:, organisation:, name: "Atelier Collectif") }
  let!(:lieu) { create(:lieu, organisation:) }
  let(:starts_at) { now.to_date.next_occurring(:wednesday).at(Tod::TimeOfDay.parse("09:00")) }
  let!(:user_amine) { create(:user, first_name: "Amine", last_name: "BENCHEIK", email: "amine@bencheik.com", organisations: [organisation]) }
  let!(:user_lea) { create(:user, first_name: "Léa", last_name: "O", organisations: [organisation]) }
  let!(:rdv) { create(:rdv, users: [user_amine, user_lea], motif:, organisation:, agents: [agent_bouba], lieu:, starts_at:) }

  before { travel_to(now) }
  before { stub_netsize_ok }

  context "annulation à l'initiative de l'usager (excused)" do
    specify do
      login_as(agent_noe, scope: :agent)
      visit admin_organisation_rdv_path(organisation, rdv)
      expect(page).to have_content("Amine BENCHEIK")
      expect(page).to have_content("Léa O")
      find("tr", text: "Amine BENCHEIK").find('div[data-toggle="dropdown"]', text: /Inscrit/).click
      accept_confirm do
        find("a.dropdown-item", text: /Annulation à l’initiative de l’usager/).click
      end
      expect(page).to have_content("mis à jour")
      expect(rdv.reload.participations.not_cancelled.map(&:user)).to contain_exactly(user_lea)
      expect(find("tr", text: "Amine BENCHEIK").find('div[data-toggle="dropdown"]').text).to include("Annulé")
      # on s'attend à ce que soient envoyés : un mail à l'usager + un SMS à l'usager + un mail à l'agent
      perform_enqueued_jobs
      expect(Receipt.exists?(user_id: user_amine.id, channel: "sms", event: "participation_cancelled")).to be true
      open_email("amine@bencheik.com")
      expect(current_email).to have_content("a bien été annulée à votre demande")

      open_email("bouba@service.fr")
      expect(current_email).to have_content("La participation de Amine BENCHEIK au RDV collectif le mercredi 3/12 à 09h00 a été annulée par Noé Jacquet")
    end
  end

  context "annulation à l'initiative du service (revoked)" do
    specify do
      login_as(agent_noe, scope: :agent)
      visit admin_organisation_rdv_path(organisation, rdv)
      find("tr", text: "Amine BENCHEIK").find('div[data-toggle="dropdown"]', text: /Inscrit/).click
      accept_confirm do
        find("a.dropdown-item", text: /Annulation à l’initiative du service/).click
      end
      expect(page).to have_content("mis à jour")
      expect(rdv.reload.participations.not_cancelled.map(&:user)).to contain_exactly(user_lea)
      expect(find("tr", text: "Amine BENCHEIK").find('div[data-toggle="dropdown"]').text).to include("Annulé")
      perform_enqueued_jobs
      expect(Receipt.exists?(user_id: user_amine.id, channel: "sms", event: "participation_cancelled")).to be true
      open_email("amine@bencheik.com")
      expect(current_email).to have_content("a été annulée pour raison administrative")
      open_email("bouba@service.fr")
      expect(current_email).to have_content("La participation de Amine BENCHEIK au RDV collectif le mercredi 3/12 à 09h00 a été annulée par Noé Jacquet")
    end
  end
end
