class ParticipationBlueprint < Blueprinter::Base
  identifier :id

  fields :status, :send_lifecycle_notifications, :send_reminder_notification, :created_by

  association :user, blueprint: UserBlueprint
  association :prescripteur, blueprint: PrescripteurBlueprint
end
