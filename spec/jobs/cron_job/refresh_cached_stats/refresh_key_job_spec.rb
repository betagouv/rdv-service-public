RSpec.describe CronJob::RefreshCachedStats::RefreshKeyJob do
  context "chiffres reçus correctement" do
    specify do
      allow(MetabaseApi).to receive(:sql_query).and_return([{ "c" => "3 706 950" }])
      described_class.new.perform(key: "stats.both_instances.1_year.rdvs_count")
      expect(Rails.cache.fetch("stats.both_instances.1_year.rdvs_count")).to eq(3_706_950)
    end
  end

  context "chiffres formattés avec des virgules" do
    specify do
      allow(MetabaseApi).to receive(:sql_query).and_return([{ "c" => "3,706,950" }])
      described_class.new.perform(key: "stats.both_instances.1_year.rdvs_count")
      expect(Rails.cache.fetch("stats.both_instances.1_year.rdvs_count")).to eq(3_706_950)
    end
  end

  context "chiffres similaires dans le cache avant" do
    it "met à jour le cache" do
      Rails.cache.write("stats.both_instances.1_year.rdvs_count", 3_500_000)
      allow(MetabaseApi).to receive(:sql_query).and_return([{ "c" => "3 706 950" }])
      described_class.new.perform(key: "stats.both_instances.1_year.rdvs_count")
      expect(Rails.cache.fetch("stats.both_instances.1_year.rdvs_count")).to eq(3_706_950)
    end
  end

  context "chiffres qui paraissent aberrants" do
    it "ne remplace pas les valeurs dans le cache, valeurs aberrantes ignorées" do
      Rails.cache.write("stats.both_instances.1_year.rdvs_count", 3_500_000)
      allow(MetabaseApi).to receive(:sql_query).and_return([{ "c" => "3000" }])
      expect do
        described_class.new.perform(key: "stats.both_instances.1_year.rdvs_count")
      end.to raise_error(CronJob::RefreshCachedStats::SuspiciousFigureError)
      expect(Rails.cache.fetch("stats.both_instances.1_year.rdvs_count")).to eq(3_500_000)
    end
  end

  context "chiffres qui paraissent aberrants mais on force le rafraîchissement" do
    it "ne remplace pas les valeurs dans le cache, valeurs aberrantes ignorées" do
      Rails.cache.write("stats.both_instances.1_year.rdvs_count", 3_500_000)
      allow(MetabaseApi).to receive(:sql_query).and_return([{ "c" => "3000" }])
      expect do
        described_class.new.perform(key: "stats.both_instances.1_year.rdvs_count", force: true)
      end.not_to raise_error
      expect(Rails.cache.fetch("stats.both_instances.1_year.rdvs_count")).to eq(3_000)
    end
  end

  context "pour la carte des lieux, sans valeur précédente" do
    specify do
      allow(MetabaseApi).to receive(:sql_query).and_return(
        [
          {
            "organisation_name" => "Inclusion Numérique Allier",
            "type_organisation" => "RDV Solidarités",
            "latitude" => "46,29",
            "longitude" => "2,74",
          },
          {
            "organisation_name" => "SDSEI Est Béarn - site de NAY",
            "type_organisation" => "RDV Solidarités",
            "latitude" => "43,19",
            "longitude" => "-0,11",
          },
        ]
      )
      expect { described_class.new.perform(key: "stats.both_instances.lieux_map_data.v2") }.not_to raise_error
      expect(Rails.cache.fetch("stats.both_instances.lieux_map_data.v2").count).to eq(2)
      expect(Rails.cache.fetch("stats.both_instances.lieux_map_data.v2")[0]["organisation_name"]).to eq("Inclusion Numérique Allier")
    end
  end

  context "pour la carte des lieux, avec un nombre de lignes reçus suspicieusement bas" do
    let(:row) do
      {
        "organisation_name" => "Inclusion Numérique Allier",
        "type_organisation" => "RDV Solidarités",
        "latitude" => "46,29",
        "longitude" => "2,74",
      }
    end

    before do
      # On simule que les données précédentes étaient beaucoup plus complètes, 12 lignes
      Rails.cache.write("stats.both_instances.lieux_map_data.v2", [row] * 12)
    end

    specify do
      allow(MetabaseApi).to receive(:sql_query).and_return([row])
      expect do
        described_class.new.perform(key: "stats.both_instances.lieux_map_data.v2")
      end.to raise_error(CronJob::RefreshCachedStats::SuspiciousFigureError)
      expect(Rails.cache.fetch("stats.both_instances.lieux_map_data.v2").count).to eq(12)
      expect(Rails.cache.fetch("stats.both_instances.lieux_map_data.v2")[0]["organisation_name"]).to eq("Inclusion Numérique Allier")
    end
  end
end
