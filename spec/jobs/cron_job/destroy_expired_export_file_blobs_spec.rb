RSpec.describe CronJob::DestroyExpiredExportFileBlobs do
  it "deletes only expired exports' blobs" do
    expired_export = create(:export).tap { _1.update!(expires_at: 2.hours.ago) }
    not_expired_export = create(:export).tap { _1.update!(expires_at: 2.hours.from_now) }

    _expired_blob = ExportFileBlob.create!(export: expired_export, data: "abcde")
    not_expired_blob = ExportFileBlob.create!(export: not_expired_export, data: "abcde")

    expect { described_class.new.perform }.to change(ExportFileBlob, :count).by(-1)

    expect(ExportFileBlob.all).to eq([not_expired_blob])
    expect(Export.all).to contain_exactly(not_expired_export, expired_export)
  end
end
