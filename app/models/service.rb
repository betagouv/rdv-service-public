class Service < ApplicationRecord
  has_many :pros, dependent: :nullify
  has_many :motifs, dependent: :destroy
  belongs_to :organisation
  validates :name, presence: true, uniqueness: { case_sensitive: false }

  def self.with_online_motif_in_departement(departement)
    organisations_ids_from_departement = Organisation.where(departement: departement).pluck(:id)
    services_ids_with_at_least_one_motif = Motif.active.online.where(organisation_id: organisations_ids_from_departement).joins(:plage_ouvertures).pluck(:service_id).uniq
    Service.where(id: services_ids_with_at_least_one_motif).includes(:motifs).merge(Motif.active).references(:motifs)
  end
end
