class CleanupExportJob < ApplicationJob
  queue_as :default

  def perform(export_id)
    Export.find(export_id).destroy
  end
end
