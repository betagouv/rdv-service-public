# frozen_string_literal: true

class AgentBlueprint < Blueprinter::Base
  identifier :id

  fields :first_name, :last_name, :email
end
