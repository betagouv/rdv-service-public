class Service < ApplicationRecord
  has_many :agents, dependent: :nullify
  has_many :motifs, dependent: :destroy
  has_many :motif_libelles, dependent: :destroy
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  SECRETARIAT = 'Secrétariat'.freeze

  scope :with_motifs, -> { where.not(name: SECRETARIAT) }

  scope :with_online_and_active_motifs_for_departement, lambda { |departement|
                                                          where(id: Motif.online
                                                          .active
                                                          .joins(:organisation, :plage_ouvertures)
                                                          .where(organisations: { departement: departement })
                                                          .pluck(:service_id)
                                                          .uniq)
                                                        }

  def secretariat?
    name == SECRETARIAT
  end
end
