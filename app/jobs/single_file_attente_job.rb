class SingleFileAttenteJob < ApplicationJob
  queue_as :latency_5mn

  def perform(file_attente_id)
    fa = FileAttente.find(file_attente_id)

    fa.send_notification_if_valid
  end
end
