RSpec.describe "Broken links in the application are visible in Sentry" do
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let(:organisation) { create(:organisation) }

  let(:broken_agenda_path) { admin_organisation_agent_agenda_path(organisation, agent.id + 1) }

  context "when the agent has kept a link to an obsolete page" do
    context "and they are logged in" do
      before { login_as(agent, scope: :agent) }

      it "doesn't send anything to Sentry" do
        expect do
          visit broken_agenda_path
        end.to raise_error(ActiveRecord::RecordNotFound)

        expect(sentry_events).to be_empty
      end
    end

    context "and they are not logged in" do
      it "doesn't send anything to Sentry" do
        visit broken_agenda_path
        fill_in "Email", with: agent.email
        fill_in :password, with: "Correcth0rse!"
        expect { click_on "Se connecter" }.to raise_error(ActiveRecord::RecordNotFound)

        expect(sentry_events).to be_empty
      end
    end
  end

  context "when there actually is a broken link" do
    context "and they are logged in" do
      before { login_as(agent, scope: :agent) }

      it "sends an event to Sentry" do
        default_url_options[:host] = "http://www.rdv-mairie-test.localhost"
        Capybara.current_session.driver.header "Referer", root_url
        expect { visit broken_agenda_path }.to raise_error(ActiveRecord::RecordNotFound)

        expect(sentry_events).not_to be_empty
      end
    end

    context "and they are not logged in (their session may have expired since the page was loaded)" do
      it "sends an event to Sentry" do
        visit broken_agenda_path
        fill_in "Email", with: agent.email
        fill_in :password, with: "Correcth0rse!"
        expect { click_on "Se connecter" }.to raise_error(ActiveRecord::RecordNotFound)

        expect(sentry_events).not_to be_empty
      end
    end
  end
end
