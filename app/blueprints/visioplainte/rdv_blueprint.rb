class Visioplainte::RdvBlueprint < Blueprinter::Base
  identifier :id

  fields :starts_at, :created_at, :duration_in_min, :ends_at

  field :users do |rdv, _options|
    rdv.users.map do |user|
      { id: user.id }
    end
  end

  field :guichet do |rdv, _options|
    guichet = rdv.agents.first
    {
      id: guichet.id,
      name: guichet.full_name,
    }
  end
end
