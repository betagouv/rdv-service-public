# frozen_string_literal: true

class RdvsUserBlueprint < Blueprinter::Base
  identifier :id

  fields :status, :send_lifecycle_notifications, :send_reminder_notification

  association :user, blueprint: UserBlueprint
end
