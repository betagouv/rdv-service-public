class Visioplainte::RdvBlueprint < Blueprinter::Base
  identifier :id

  fields :starts_at, :created_at, :duration_in_min, :ends_at, :status

  field :user_id do |rdv, _options|
    rdv.users.first.id
  end

  field :guichet do |rdv, _options|
    guichet = rdv.agents.first
    {
      id: guichet.id,
      name: guichet.full_name,
    }
  end
end
