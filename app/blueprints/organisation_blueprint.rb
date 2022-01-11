# frozen_string_literal: true

class OrganisationBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :phone_number, :email
end
