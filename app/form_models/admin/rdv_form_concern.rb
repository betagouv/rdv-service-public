module Admin::RdvFormConcern
  extend ActiveSupport::Concern

  included do
    include ActiveModel::Cautions
    include ActiveModel::Cautions::Callbacks
    include ActiveModel::Cautions::SafetyDecision

    attr_accessor :rdv

    delegate(*::Rdv.attribute_names, to: :rdv)
    delegate :motif, :organisation, :agents, :users, to: :rdv
    delegate :overlapping_plages_ouvertures, :overlapping_plages_ouvertures?, to: :rdv

    validate :validate_rdv
    caution :warn_overlapping_plage_ouverture
  end

  def save
    valid? && rdv.save
  end

  private

  def validate_rdv
    return unless rdv.valid?

    rdv.errors.each { errors.add(_1, _2) }
  end

  def warn_overlapping_plage_ouverture
    return true unless overlapping_plages_ouvertures?

    overlapping_plages_ouvertures
      .map { PlageOuverturePresenter.new(_1, agent_context) }
      .each { warnings.add(:base, _1.overlaps_rdv_error_message, active: true) }
  end
end
