class OrganisationBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :phone_number, :email, :verticale
end
