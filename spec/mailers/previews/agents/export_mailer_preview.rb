class Agents::ExportMailerPreview < ActionMailer::Preview
  def rdv_export
    Agents::ExportMailer.rdv_export(Export.last)
  end

  def participations_export
    Agents::ExportMailer.participations_export(Export.last)
  end
end
