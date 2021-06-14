# frozen_string_literal: true

class AgentWithTokenAuth < Agent
  self.table_name = "agents"
  include DeviseTokenAuth::Concerns::User

  def as_json(options = {})
    json = super(options)
    json["organisation_ids"] = organisation_ids
    json
  end
end
