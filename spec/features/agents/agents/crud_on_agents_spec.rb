RSpec.describe "Agents can be managed by organisation admins" do
  let(:territory) { create(:territory) }
  let(:pmi) { create(:service, name: "PMI", territories: [territory]) }
  let(:other_service) { create(:service, territories: []) }
  let(:organisation1) { create(:organisation, territory: territory) }
  let(:organisation2) { create(:organisation, territory: territory) }
  let(:organisation_admin) { create(:agent, service: pmi, admin_role_in_organisations: [organisation1, organisation2]) }
  let(:territory_admin) { create(:agent, service: pmi, admin_role_in_organisations: [organisation1, organisation2]) }

  context "inviting an agent in an existing service" do
    before do
      login_as(organisation_admin, scope: :agent)
      visit admin_organisation_agents_path(organisation1)
    end

    it "allows adding an agent in two different organisations" do
      click_link("Ajouter un agent", match: :first)
      fill_in("Email", with: "bob@test.com")
      select(pmi.name, from: "Services")
      click_button("Envoyer une invitation")
      expect(Agent.count).to eq(2)

      visit admin_organisation_agents_path(organisation2)
      click_link("Ajouter un agent", match: :first)
      fill_in("Email", with: "bob@test.com")
      click_button("Envoyer une invitation")
      expect(Agent.count).to eq(2)

      expect(page).to have_content("Invitations en cours")
      expect(organisation2.reload.agents.count).to eq 2
    end

    describe "invitation email domains" do
      around { |example| perform_enqueued_jobs { example.run } }

      context "when the organisation is using rdv_aide_numerique verticale" do
        let!(:organisation1) { create(:organisation, territory: territory, verticale: :rdv_aide_numerique) }

        it "allows inviting agents on the correct domain" do
          click_link "Agents"
          click_link "Ajouter un agent", match: :first
          fill_in "Email", with: "jean@paul.com"
          select(pmi.name, from: "Services")
          click_button "Envoyer une invitation"

          open_email("jean@paul.com")
          expect(current_email.subject).to eq "Vous avez été invité sur RDV Aide Numérique"
          expect(current_email.body).to include "rejoindre RDV Aide Numérique"
        end
      end

      context "when the organisation is using rdv_insertion verticale" do
        let!(:organisation1) { create(:organisation, territory: territory, verticale: :rdv_insertion) }

        it "allows inviting agents on the correct domain" do
          click_link "Agents"
          click_link "Ajouter un agent", match: :first
          fill_in "Email", with: "jean@paul.com"
          select(pmi.name, from: "Services")
          click_button "Envoyer une invitation"

          open_email("jean@paul.com")
          expect(current_email.subject).to eq "Vous avez été invité sur RDV Solidarités"
        end
      end
    end
  end
end
