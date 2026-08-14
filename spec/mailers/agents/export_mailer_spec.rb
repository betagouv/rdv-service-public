RSpec.describe Agents::ExportMailer do
  it "sends emails for all the possible export types" do
    Export.export_types.each_key do |export_type|
      export = create(:export, export_type:)
      expect { described_class.export_ready(export.id).deliver_now }.to change(ActionMailer::Base.deliveries, :size).by(1)
    end
  end

  it "adjusts the subject depending on export type" do
    travel_to(Time.zone.parse("2026-09-22 16:00"))

    rdv_export = create(:export, export_type: Export::RDV_EXPORT)
    expect(described_class.export_ready(rdv_export.id).subject).to eq("Export des RDVs du 22/09/2026 à 16:00")

    participation_export = create(:export, Export::PARTICIPATIONS_EXPORT)
    expect(described_class.export_ready(participation_export.id).subject).to eq("Export des RDVs par usager du 22/09/2026 à 16:00")
  end
end
