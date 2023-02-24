# frozen_string_literal: true

describe "can search users" do
  context "when user is visible only in organisation" do
    it "can't see user that match search query from other organsiation" do
      territory = create(:territory, visible_users_throughout_the_territory: false)
      organisation = create(:organisation, territory: territory)
      other_organisation = create(:organisation, territory: territory)
      agent = create(:agent, basic_role_in_organisations: [organisation])
      user = create(:user, first_name: "Tanguy", last_name: "Laverdure", organisations: [organisation])
      other_organisation_user = create(:user, first_name: "Tanguy", last_name: "De retour", organisations: [other_organisation])

      login_as(agent, scope: :agent)
      visit admin_organisation_users_path(organisation, search: "Tanguy")

      expect(page).to have_content(user.last_name.upcase)
      expect(page).not_to have_content(other_organisation_user.last_name.upcase)
    end

    it "see users that match search query" do
      territory = create(:territory, visible_users_throughout_the_territory: false)
      organisation = create(:organisation, territory: territory)
      agent = create(:agent, basic_role_in_organisations: [organisation])
      user = create(:user, first_name: "Tanguy", last_name: "Laverdure", organisations: [organisation])
      other_user = create(:user, first_name: "Tanguy", last_name: "Deretour", organisations: [organisation])

      login_as(agent, scope: :agent)
      visit admin_organisation_users_path(organisation, search: "Tanguy")

      expect(page).to have_content(user.last_name.upcase)
      expect(page).to have_content(other_user.last_name.upcase)
    end
  end

  context "when user is visible through territor" do
    it "see all users that match search query" do
      territory = create(:territory, visible_users_throughout_the_territory: true)
      organisation = create(:organisation, territory: territory)
      other_organisation = create(:organisation, territory: territory)
      agent = create(:agent, basic_role_in_organisations: [organisation])
      user = create(:user, first_name: "Tanguy", last_name: "Laverdure", organisations: [organisation])
      other_organisation_user = create(:user, first_name: "Tanguy", last_name: "Deretour", organisations: [other_organisation])

      login_as(agent, scope: :agent)
      visit admin_organisation_users_path(organisation, search: "Tanguy")

      expect(page).to have_content(user.last_name.upcase)
      expect(page).to have_content(other_organisation_user.last_name.upcase)
    end

    it "see all users in one page" do
      territory = create(:territory, visible_users_throughout_the_territory: true)
      organisations = create_list(:organisation, 15, territory: territory)
      agent = create(:agent, basic_role_in_organisations: organisations)
      create_list(:user, 8, first_name: "Tanguy", last_name: "Laverdure", organisations: organisations.sample(rand(15)))

      login_as(agent, scope: :agent)
      visit admin_organisation_users_path(organisations.first, search: "Tanguy")

      expect(page).not_to have_content("Suivant")
    end
  end
end
