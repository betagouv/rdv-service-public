# frozen_string_literal: true

class RdvsUsersBlueprint < Blueprinter::Base
  fields :status, :send_lifecycle_notifications, :send_reminder_notification

  association :user, blueprint: UserBlueprint
end
