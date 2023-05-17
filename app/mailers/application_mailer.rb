# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  self.deliver_later_queue_name = :mailers

  include CommonMailer
  prepend IcsMultipartAttached

  append_view_path Rails.root.join("app/views/mailers")

  self.delivery_job = CustomMailerDeliveryJob

  # Cet email est utilisé comme adresse de "Reply-To" pour les e-mails
  # qui contiennent des ICS. Lorsque l'événement ICS est acceptée par le
  # client mail / calendrier, ce client mail envoie un accusé de réception
  # à cette adresse (ex: "Accepted: RDV Consultation médicale ").
  # Puisque c'est une adresse technique, c'est OK qu'elle soit en rdv-solidarites.fr.
  SECRETARIAT_EMAIL = "secretariat-auto@rdv-solidarites.fr"
end
