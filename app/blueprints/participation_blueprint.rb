class ParticipationBlueprint < Blueprinter::Base
  identifier :id

  fields :status, :send_lifecycle_notifications, :send_reminder_notification, :created_by_type

  # Retrocompatibilité avec l'ancien format de l'API pour created_by
  field :created_by do |participation, _options|
    case participation.created_by
    when Agent
      "agent"
    when User
      "user"
    when Prescripteur
      "prescripteur"
    end
  end

  association :user, blueprint: UserBlueprint
end
