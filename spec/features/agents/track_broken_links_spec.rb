RSpec.describe "Broken links in the application are visible in Sentry" do
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let(:organisation) { create(:organisation) }

  let(:broken_agenda_path) { admin_organisation_agent_agenda_path(organisation, agent.id + 1) }

  context "when the agent has kept a link to an obsolete page" do
    context "and they are logged in" do
      before { login_as(agent, scope: :agent) }

      it "doesn't send anything to Sentry" do
        # C'est très difficile de vérifier que les sentry_events sont les bons, donc le plus simple
        # pour cette spec était d'observer les appels au logger interne de Sentry.
        expect_any_instance_of(Sentry::Client).to receive(:log_debug).with("Discarded event because before_send returned nil")
        expect do
          visit broken_agenda_path
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "and they are not logged in" do
      it "doesn't send anything to Sentry" do
        expect_any_instance_of(Sentry::Client).to receive(:log_debug).with("Discarded event because before_send returned nil")
        visit broken_agenda_path
        fill_in "Email", with: agent.email
        fill_in :password, with: "Correcth0rse!"
        expect { click_on "Se connecter" }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
