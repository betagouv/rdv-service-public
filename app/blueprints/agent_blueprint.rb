class AgentBlueprint < Blueprinter::Base
  identifier :id

  fields :first_name, :last_name, :email, :inclusion_connect_open_id_sub
end
