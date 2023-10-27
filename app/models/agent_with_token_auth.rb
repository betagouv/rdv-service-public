class AgentWithTokenAuth < Agent
  self.table_name = "agents"
  include DeviseTokenAuth::Concerns::User
end
