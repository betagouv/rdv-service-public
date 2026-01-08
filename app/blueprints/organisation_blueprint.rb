class OrganisationBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :phone_number, :email, :website, :verticale, :public_link_id
end
