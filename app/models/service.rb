class Service < ApplicationRecord
  has_many :agents, dependent: :nullify
  has_many :motifs, dependent: :destroy
  has_many :motif_libelles, dependent: :destroy
  validates :name, :short_name, presence: true, uniqueness: { case_sensitive: false }
  SECRETARIAT = 'Secrétariat'.freeze

  scope :with_motifs, -> { where.not(name: SECRETARIAT) }
  scope :secretariat, -> { where(name: SECRETARIAT).first }

  scope :with_online_and_active_motifs_for_departement, lambda { |departement|
                                                          where(id: Motif.reservable_online
                                                          .active
                                                          .joins(:organisation, :plage_ouvertures)
                                                          .where(organisations: { departement: departement })
                                                          .pluck(:service_id)
                                                          .uniq)
                                                        }

  def secretariat?
    name == SECRETARIAT
  end

  def self.ehpad
    find_by!(name: 'EHPAD')
  end
end
