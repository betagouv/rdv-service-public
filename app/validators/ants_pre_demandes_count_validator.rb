# NOTE: ceci n’est pas un vrai validateur compatible ActiveModel mais pourrait le devenir

class AntsPreDemandesCountValidator
  MIN = 1
  MAX = 6
  ERROR_MESSAGE = "Veuillez choisir un nombre de pré-demandes entre 1 et 6".freeze

  # cette méthode est extraite pour être appelée facilement hors d'un contexte ActiveRecord
  def self.count_valid?(value)
    value.blank? || # ce cas devrait être géré par un autre validateur de présence
      value.to_i.between?(1, 6)
  end
end
