RSpec.describe CronJob::DestroyOldVersions, versioning: true do
  before do
    PaperTrail.request.whodunnit = "Francis Factice"
  end

  context "for a table with personal information" do
    let!(:recent_user) do
      travel_to(11.months.ago) { create(:user) }
    end

    let!(:old_user) do
      travel_to(13.months.ago) { create(:user) }
    end

    it "complies with the RGPD and destroys the version after a year" do
      described_class.new.perform

      expect(recent_user.versions).to be_present
      expect(old_user.versions).to be_empty
    end
  end

  context "for a table with no personal information" do
    let!(:very_recent_motif) do
      travel_to(11.months.ago) { create(:motif) }
    end

    let!(:recent_motif) do
      travel_to((4.years + 11.months).ago) { create(:motif) }
    end

    let!(:old_motif) do
      travel_to((5.years + 3.days).ago) { create(:motif) }
    end

    it "keeps the records for a very long time, but deletes the personal information in the version" do
      described_class.new.perform

      expect(very_recent_motif.versions).to be_present
      expect(recent_motif.versions).to be_present
      expect(old_motif.versions).to be_blank

      expect(very_recent_motif.versions.first.whodunnit).to be_present
      expect(recent_motif.versions.first.whodunnit).to be_blank
    end
  end
end
