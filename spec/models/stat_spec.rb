# frozen_string_literal: true

describe Stat, type: :model do
  describe "#rdvs_group_by_type" do
    it "return empty hash without rdv" do
      stats = described_class.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_type).to eq({})
    end

    it "return 2=>1 with one home rdv" do
      home_motif = create(:motif, location_type: :home)
      create(:rdv, motif: home_motif, created_at: DateTime.new(2020, 4, 7, 10, 0))
      stats = described_class.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_type[["à domicile", "05/04/2020"]]).to eq(1)
    end

    it "return 2=>2 with two home rdv" do
      home_motif = create(:motif, location_type: :home)
      create_list(:rdv, 2, motif: home_motif, created_at: DateTime.new(2020, 4, 7, 10, 0))
      stats = described_class.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_type[["à domicile", "05/04/2020"]]).to eq(2)
    end

    it "return 2=>2 with two different motif of home rdv" do
      home_motif = create(:motif, location_type: :home)
      other_home_motif = create(:motif, location_type: :home)
      create(:rdv, motif: home_motif, created_at: DateTime.new(2020, 4, 7, 10, 0))
      create(:rdv, motif: other_home_motif, created_at: DateTime.new(2020, 4, 7, 10, 0))
      stats = described_class.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_type[["à domicile", "05/04/2020"]]).to eq(2)
    end

    it "return {2=>1, 1=>1} with one home rdv and one phone" do
      home_motif = create(:motif, location_type: :home)
      phone_motif = create(:motif, location_type: :phone)
      create(:rdv, motif: home_motif, created_at: DateTime.new(2020, 4, 7, 10, 0))
      create(:rdv, motif: phone_motif, created_at: DateTime.new(2020, 4, 7, 11, 0))
      stats = described_class.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_type[["à domicile", "05/04/2020"]]).to eq(1)
      expect(stats.rdvs_group_by_type[["par téléphone", "05/04/2020"]]).to eq(1)
    end

    it "return {2=>1, 1=>1, 0=>1 with each available motif" do
      home_motif = create(:motif, location_type: :home)
      phone_motif = create(:motif, location_type: :phone)
      public_office_motif = create(:motif, location_type: :public_office)
      create(:rdv, motif: home_motif, created_at: DateTime.new(2020, 4, 7, 10, 0))
      create(:rdv, motif: phone_motif, created_at: DateTime.new(2020, 4, 7, 11, 0))
      create(:rdv, motif: public_office_motif, created_at: DateTime.new(2020, 4, 7, 9, 40))
      stats = described_class.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_type[["à domicile", "05/04/2020"]]).to eq(1)
      expect(stats.rdvs_group_by_type[["par téléphone", "05/04/2020"]]).to eq(1)
      expect(stats.rdvs_group_by_type[["sur place", "05/04/2020"]]).to eq(1)
    end
  end

  describe "#users_group_by_week" do
    it "returns user count group by created at" do
      now = Time.zone.parse("20220123 13:00")
      travel_to(now)
      create(:user)
      stats = described_class.new(users: User.all)
      expect(stats.users_group_by_week).to eq({ now.strftime("%d/%m/%Y") => 1 })
    end
  end

  describe "#organisations_group_by_week" do
    it "returns organisations count group by created at" do
      now = Time.zone.parse("20220123 13:00")
      travel_to(now)
      create(:organisation)
      stats = described_class.new(organisations: Organisation.all)
      expect(stats.organisations_group_by_week).to eq({ now.strftime("%d/%m/%Y") => 1 })
    end
  end

  describe "#agents_for_default_range" do
    it "returns active agents only" do
      now = Time.zone.parse("20220123 13:00")
      travel_to(now)
      active_agent = create(:agent)
      create(:agent, deleted_at: now - 1.week)
      stats = described_class.new(agents: Agent.all)
      expect(stats.agents_for_default_range).to eq([active_agent])
    end
  end

  describe "#agents_group_by_week" do
    it "returns active agents count group by week" do
      now = Time.zone.parse("20220123 13:00")
      travel_to(now)
      create(:agent)
      create(:agent, deleted_at: now - 1.week)
      stats = described_class.new(agents: Agent.all)
      expect(stats.agents_group_by_week).to eq({ now.strftime("%d/%m/%Y") => 1 })
    end
  end

  describe "#rdvs_group_by_departement" do
    it "returns rdv group by département" do
      now = Time.zone.parse("20220123 13:00")
      travel_to(now)
      home_motif = create(:motif, location_type: :home)
      create(:rdv, motif: home_motif, created_at: now)
      stats = described_class.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_departement).to eq({ ["2", now.strftime("%d/%m/%Y")] => 1 })
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
      expect(stats.rdvs_group_by_service).to eq({ ["PMI", now.strftime("%d/%m/%Y")] => 1 })
    end
  end

  describe "#rdvs_group_by_status" do
    it "returns rdv group by status" do
      now = Time.zone.parse("20220123 13:00")
      travel_to(now - 1.week)
      create(:rdv, starts_at: now - 1.week, status: :unknown)
      travel_to(now)
      stats = described_class.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_status).to eq({ ["État indéterminé", (now - 1.week).strftime("%d/%m/%Y")] => 100 })
    end
  end
end
