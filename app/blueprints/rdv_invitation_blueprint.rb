class RdvInvitationBlueprint < Blueprinter::Base
  identifier :id

  fields :cancelled, :rdv_id, :created_at, :updated_at

  association :motif, blueprint: MotifBlueprint
  association :lieu, blueprint: LieuBlueprint
  association :inviting_agent, blueprint: AgentBlueprint
end
