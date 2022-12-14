# frozen_string_literal: true

RSpec.describe "Error monitoring" do
  stub_sentry_events

  describe "pages with a 4xx status" do
    let(:rdv) { create(:rdv) }

    around do |example|
      previous = Capybara.raise_server_errors

      Capybara.raise_server_errors = false
      example.run
      Capybara.raise_server_errors = previous
    end

    before do
      login_as(rdv.agents.first, scope: :agent)
      visit admin_organisation_rdvs_path(rdv.organisation)
    end

    context "when there is a broken link inside the app", js: true do
      before do
        # Let's break the link
        page.execute_script(<<-JS
          let link = document.querySelector("[href='#{admin_organisation_rdv_path(rdv.organisation, rdv)}']")
          link.setAttribute("href", "#{admin_organisation_rdv_path(rdv.organisation, rdv.id + 1)})")
        JS
                           )
      end

      it "warns us through Sentry" do
        click_link("durée")
        expect(page).to have_content("RDV") # Wait for the click to be processed
        expect(sentry_events.count).to eq 1
        expect(sentry_events.last.exception.values.first.type).to eq("ActiveRecord::RecordNotFound")
      end
    end

    context "when there is a broken link somewhere else" do
      it "doesnt spam Sentry, because there's nothing we can do to fix outside links" do
        visit admin_organisation_rdvs_path(rdv.organisation, rdv.id + 1)
        expect(page).to have_content("RDV") # Wait for the click to be processed
        expect(sentry_events.count).to eq 0
      end
    end
  end
end
