class AiguillageUsagerForm
  include ActiveModel::Model
  attr_accessor :raison

  def initialize(raison: nil)
    @raison = raison&.to_sym
  end

  def raisons_options
    [
      { value: :creneaux, label: "Vous souhaitez prendre un RDV" },
      { value: :annuler, label: "Vous souhaitez annuler votre RDV" },
      { value: :autre, label: "Autre raison" },
    ]
  end

  def raison_creneaux? = raison == :creneaux
  def raison_annuler? = raison == :annuler
  def raison_autre? = raison == :autre

  def raison_label = raisons_options.find { _1[:value] == raison }[:label]

  def should_redirect_to_demande_support? = raison_autre?
end
