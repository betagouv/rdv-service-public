class OrganisationBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :phone_number, :email, :website, :verticale, :time_zone
end
