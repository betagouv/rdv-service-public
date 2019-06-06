class PopulateSpecialite < ActiveRecord::Migration[5.2]
  def change
    %w( Médecin Infirmière Puéricultrice Sage-femme Psychologue Secrétaire ).each do |spe|
      Specialite.create(name:  spe)
    end
  end
end
