class SingleFileAttenteJob < ApplicationJob
  queue_as :latency_5mn

  def perform(file_attente_id)
    fa = FileAttente.find_by(id: file_attente_id)
    return unless fa

    fa.send_notification_if_valid
  end
end
