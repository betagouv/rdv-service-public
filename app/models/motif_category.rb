class MotifCategory < ApplicationRecord
  has_paper_trail

  # Relations
  has_many :motifs, dependent: :nullify
  has_and_belongs_to_many :territories

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :short_name, presence: true, uniqueness: true

  scope :requires_ants_predemande_number, -> { where(name: Api::Ants::EditorController::ANTS_MOTIF_CATEGORY_NAMES) }

  def requires_ants_predemande_number?
    name.in?(Api::Ants::EditorController::ANTS_MOTIF_CATEGORY_NAMES)
  end
end
