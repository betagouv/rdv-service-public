class Agents::ExportMailerPreview < ActionMailer::Preview
  def export_ready
    Agents::ExportMailer.export_ready(Export.last)
  end
end
