# frozen_string_literal: true

class RdvBlueprint < Blueprinter::Base
  identifier :id

  fields :uuid, :duration_in_min, :starts_at, :address, :context

  field :status do |object, options|
    if options[:api_options]&.include?("rdv_status_compatibility1")
      status_compatibility1(object)
    else
      object.status
    end
  end

  def self.status_compatibility1(object)
    # See Issue #1657
    case object.status
    when "noshow"
      "notexcused"
    when "revoked"
      "excused"
    else
      object.status
    end
  end

  association :organisation, blueprint: OrganisationBlueprint
  association :motif, blueprint: MotifBlueprint
  association :users, blueprint: UserBlueprint
  association :agents, blueprint: AgentBlueprint
  association :lieu, blueprint: LieuBlueprint
end
