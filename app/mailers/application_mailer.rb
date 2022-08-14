# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  self.deliver_later_queue_name = :mailers

  include DomainConcern
  helper_method :domain

  prepend IcsMultipartAttached

  default from: SUPPORT_EMAIL
  append_view_path Rails.root.join("app/views/mailers")
  layout "mailer"
  helper RdvSolidaritesInstanceNameHelper
end
