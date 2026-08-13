RSpec.describe ExportSendEmailJob do
  it "sends emails for all the possible export types" do
    if Export.export_types.keys != described_class::MAILER_CLASS_FOR_EXPORT_TYPE.keys
      raise <<~ERROR
        Il faut définir le mailer pour le nouveau type d'export pour que cette classe puisse envoyer un mail.
        Vérifiez aussi les autres usages de export.export_type dans ce job.
      ERROR
    end
  end
end
