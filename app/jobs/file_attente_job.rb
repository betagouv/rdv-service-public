class FileAttenteJob < ApplicationJob
  def perform
    FileAttente.send_notifications
  end
end
