class FileAttenteJob < ApplicationJob
  def perform
    FileAttente.send_notifications if Flipflop.file_attente?
  end
end
