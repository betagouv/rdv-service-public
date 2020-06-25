class UserProfile < ApplicationRecord
  belongs_to :organisation
  belongs_to :user

  validates :user_id, uniqueness: { scope: :organisation }

  enum logement: { sdf: 0, heberge: 1, en_accession_propriete: 2, proprietaire: 3, autre: 4, locataire: 5 }
end
