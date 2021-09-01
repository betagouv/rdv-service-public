# frozen_string_literal: true

# cf https://github.com/thoughtbot/administrate/blob/master/docs/adding_controllers_without_related_model.md

require "administrate/custom_dashboard"

class MailerPreviewDashboard < Administrate::CustomDashboard # remove this?
  resource "MailerPreview" # for administrate views, not an actual resource
end
