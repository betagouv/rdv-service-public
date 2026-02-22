RSpec.describe Stat, type: :model do
  describe "#rdvs_group_by_type" do
    let!(:organisation) { organisations(:default_org) }

    it "return empty hash without rdv" do
      stats = described_class.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_type).to eq({})
    end

    it "return 2=>1 with one home rdv" do
      home_motif = create(:motif, location_type: :home, organisation:)
      create(:rdv, motif: home_motif, created_at: Time.zone.parse("2020-04-07 10:00"), organisation:)
      stats = described_class.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_type[["à domicile", "05/04/2020"]]).to eq(1)
    end

    it "return 2=>2 with two home rdv" do
      home_motif = create(:motif, location_type: :home, organisation:)
      create_list(:rdv, 2, motif: home_motif, created_at: Time.zone.parse("2020-04-07 10:00"), organisation:)
      stats = described_class.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_type[["à domicile", "05/04/2020"]]).to eq(2)
    end

    it "return 2=>2 with two different motif of home rdv" do
      home_motif = create(:motif, location_type: :home, organisation:)
      other_home_motif = create(:motif, location_type: :home, organisation:)
      create(:rdv, motif: home_motif, created_at: Time.zone.parse("2020-04-07 10:00"), organisation:)
      create(:rdv, motif: other_home_motif, created_at: Time.zone.parse("2020-04-07 10:00"), organisation:)
      stats = described_class.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_type[["à domicile", "05/04/2020"]]).to eq(2)
    end

    it "return {2=>1, 1=>1} with one home rdv and one phone" do
      home_motif = create(:motif, location_type: :home, organisation:)
      phone_motif = create(:motif, location_type: :phone, organisation:)
      create(:rdv, motif: home_motif, created_at: Time.zone.parse("2020-04-07 10:00"), organisation:)
      create(:rdv, motif: phone_motif, created_at: Time.zone.parse("2020-04-07 11:00"), organisation:)
      stats = described_class.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_type[["à domicile", "05/04/2020"]]).to eq(1)
      expect(stats.rdvs_group_by_type[["par téléphone", "05/04/2020"]]).to eq(1)
    end

    it "return {2=>1, 1=>1, 0=>1 with each available motif" do
      home_motif = create(:motif, location_type: :home, organisation:)
      phone_motif = create(:motif, location_type: :phone, organisation:)
      public_office_motif = create(:motif, location_type: :public_office, organisation:)
      create(:rdv, motif: home_motif, created_at: Time.zone.parse("2020-04-07 10:00"), organisation:)
      create(:rdv, motif: phone_motif, created_at: Time.zone.parse("2020-04-07 11:00"), organisation:)
      create(:rdv, motif: public_office_motif, created_at: Time.zone.parse("2020-04-07 09:40"), organisation:)
      stats = described_class.new(rdvs: Rdv.all)
      expect(stats.rdvs_group_by_type[["à domicile", "05/04/2020"]]).to eq(1)
      expect(stats.rdvs_group_by_type[["par téléphone", "05/04/2020"]]).to eq(1)
      expect(stats.rdvs_group_by_type[["sur place", "05/04/2020"]]).to eq(1)
    end
  end

  describe "#rdvs_group_by_service" do
    let!(:organisation) { organisations(:default_org) }

    it "returns rdv group by service" do
      now = Time.zone.parse("20220123 13:00")
      travel_to(now)
      service = create(:service, name: "PMI")
      home_motif = create(:motif, location_type: :home, service: service, organisation:)
      create(:rdv, motif: home_motif, created_at: now, organisation:)

      motif_sans_service = create(:motif, service: nil, organisation:)
      create(:rdv, motif: motif_sans_service, created_at: now, organisation:)

      stats = described_class.new(rdvs: Rdv.all)

      # Pour le moment on ne comptabilise pas les motifs sans service dans ce compte.
      # On peut changer ce comportement si on en trouve un qui a plus de sens.
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
