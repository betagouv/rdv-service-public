class ParticipationBlueprint < Blueprinter::Base
  identifier :id

  fields :status, :send_lifecycle_notifications, :send_reminder_notification, :created_by_type, :created_by_id, :prescription

  # Retrocompatibilité avec l'ancien format de l'API pour created_by
  field :created_by do |participation, _options|
    created_by_type_map = {
      "Agent" => "agent",
      "User" => "user",
      "Prescripteur" => "prescripteur",
    }

    created_by_type_map[participation.created_by_type]
  end

  association :user, blueprint: UserBlueprint
end
