# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  self.deliver_later_queue_name = :mailers

  prepend IcsMultipartAttached

  default from: "contact@rdv-solidarites.fr", reply_to: "support@rdv-solidarites.fr"
  append_view_path Rails.root.join("app/views/mailers")
  layout "mailer"
  helper RdvSolidaritesInstanceNameHelper
end
