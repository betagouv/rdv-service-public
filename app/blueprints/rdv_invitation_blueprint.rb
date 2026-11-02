class RdvInvitationBlueprint < Blueprinter::Base
  identifier :id

  fields :cancelled, :rdv_id, :created_at, :updated_at
end
