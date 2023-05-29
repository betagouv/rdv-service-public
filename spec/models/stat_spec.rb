# frozen_string_literal: true

describe Stat, type: :model do
  describe "#rdvs_group_by_type" do
    it "return empty hash without rdv" do
      stats = described_class.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_type).to eq({})
    end

    it "return 2=>1 with one home rdv" do
      home_motif = create(:motif, location_type: :home)
      create(:rdv, motif: home_motif, created_at: Time.zone.parse("2020-04-07 10:00"))
      stats = described_class.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_type[["à domicile", "05/04/2020"]]).to eq(1)
    end

    it "return 2=>2 with two home rdv" do
      home_motif = create(:motif, location_type: :home)
      create_list(:rdv, 2, motif: home_motif, created_at: Time.zone.parse("2020-04-07 10:00"))
      stats = described_class.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_type[["à domicile", "05/04/2020"]]).to eq(2)
    end

    it "return 2=>2 with two different motif of home rdv" do
      home_motif = create(:motif, location_type: :home)
      other_home_motif = create(:motif, location_type: :home)
      create(:rdv, motif: home_motif, created_at: Time.zone.parse("2020-04-07 10:00"))
      create(:rdv, motif: other_home_motif, created_at: Time.zone.parse("2020-04-07 10:00"))
      stats = described_class.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_type[["à domicile", "05/04/2020"]]).to eq(2)
    end

    it "return {2=>1, 1=>1} with one home rdv and one phone" do
      home_motif = create(:motif, location_type: :home)
      phone_motif = create(:motif, location_type: :phone)
      create(:rdv, motif: home_motif, created_at: Time.zone.parse("2020-04-07 10:00"))
      create(:rdv, motif: phone_motif, created_at: Time.zone.parse("2020-04-07 11:00"))
      stats = described_class.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_type[["à domicile", "05/04/2020"]]).to eq(1)
      expect(stats.rdvs_group_by_type[["par téléphone", "05/04/2020"]]).to eq(1)
    end

    it "return {2=>1, 1=>1, 0=>1 with each available motif" do
      home_motif = create(:motif, location_type: :home)
      phone_motif = create(:motif, location_type: :phone)
      public_office_motif = create(:motif, location_type: :public_office)
      create(:rdv, motif: home_motif, created_at: Time.zone.parse("2020-04-07 10:00"))
      create(:rdv, motif: phone_motif, created_at: Time.zone.parse("2020-04-07 11:00"))
      create(:rdv, motif: public_office_motif, created_at: Time.zone.parse("2020-04-07 09:40"))
      stats = described_class.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_type[["à domicile", "05/04/2020"]]).to eq(1)
      expect(stats.rdvs_group_by_type[["par téléphone", "05/04/2020"]]).to eq(1)
      expect(stats.rdvs_group_by_type[["sur place", "05/04/2020"]]).to eq(1)
    end
  end

  describe "#rdvs_group_by_territory_name" do
    it "returns rdv group by département" do
      now = Time.zone.parse("20220123 13:00")
      travel_to(now)
      home_motif = create(:motif, location_type: :home)
      create(:rdv, motif: home_motif, created_at: now)
      stats = described_class.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_territory_name).to eq({ ["Territoire n°2", "23/01/2022"] => 1 })
    end
  end

  describe "#rdvs_group_by_service" do
    it "returns rdv group by service" do
      now = Time.zone.parse("20220123 13:00")
      travel_to(now)
      service = create(:service, name: "PMI")
      home_motif = create(:motif, location_type: :home, service: service)
      create(:rdv, motif: home_motif, created_at: now)
      stats = described_class.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_service).to eq({ ["PMI", "23/01/2022"] => 1 })
    end
  end

  describe "#rdvs_group_by_status" do
    it "returns rdv group by status" do
      now = Time.zone.parse("20220123 13:00")
      travel_to(now - 1.week)
      create(:rdv, starts_at: now - 1.week, status: :unknown)
      travel_to(now)
      stats = described_class.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_status).to eq({ ["État indéterminé", "16/01/2022"] => 100 })
    end
  end
end
