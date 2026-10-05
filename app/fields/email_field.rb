require "administrate/field/base"

# Cet override permet d'ajouter un bouton "copier" à côté des e-mails
class EmailField < Administrate::Field::Base
  def self.searchable?
    true
  end

  def to_s
    data
  end
end
