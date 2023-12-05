class PrescripteurBlueprint < Blueprinter::Base
  identifier :id

  fields :participation_id, :first_name, :last_name, :email, :created_at, :updated_at
end
