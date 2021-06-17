# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  prepend IcsMultipartAttached

  default from: "contact@rdv-solidarites.fr"
  append_view_path Rails.root.join("app/views/mailers")
  layout "mailer"
  add_template_helper RdvSolidaritesInstanceNameHelper
end
