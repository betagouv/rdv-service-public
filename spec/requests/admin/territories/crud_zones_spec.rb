# frozen_string_literal: true

RSpec.describe "CRUD zone pour la sectorisation", type: :request do
  include Rails.application.routes.url_helpers

  let(:territory) { create(:territory, departement_number: "62") }
  let(:organisation) { create(:organisation, territory: territory) }
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation], role_in_territories: [territory]) }

  before { sign_in agent }

  describe "GET new" do
    it "return successful" do
      sector = create(:sector, territory: territory)
      get new_admin_territory_sector_zone_path(territory, sector)
      expect(response).to be_successful
    end
  end

  describe "POST create" do
    it "redirect to sector page when commit params is simple create" do
      sector = create(:sector, territory: territory)
      zone_attributes = attributes_for(:zone, sector: sector)
      post admin_territory_sector_zones_path(territory, sector), params: { zone: zone_attributes, commit: I18n.t("helpers.submit.create") }
      expect(response).to redirect_to(admin_territory_sector_path(territory, sector))
    end

    it "redirect to new zone page for city when commit params is create and new city zone" do
      sector = create(:sector, territory: territory)
      zone_attributes = {
        level: "city",
        city_code: "62040",
        city_name: "Arques",
      }
      post admin_territory_sector_zones_path(territory, sector), params: { zone: zone_attributes, commit: "Créer puis créer une autre commune" }
      expect(response).to redirect_to(new_admin_territory_sector_zone_path(territory, sector, default_zone_level: "city"))
    end

    it "redirect to new zone page for street when commit params is create and new street zone" do
      sector = create(:sector, territory: territory)
      zone_attributes = {
        level: "street",
        city_code: "62040",
        city_name: "Arques",
        street_ban_id: "62040_0020",
        street_name: "Boulevard du docteur Alexandre",
      }
      post admin_territory_sector_zones_path(territory, sector), params: { zone: zone_attributes, commit: "Créer puis créer une autre rue" }
      expect(response).to redirect_to(new_admin_territory_sector_zone_path(territory, sector, default_zone_level: "street"))
    end
  end
end
