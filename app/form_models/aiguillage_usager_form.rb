class AiguillageUsagerForm
  include ActiveModel::Model
  attr_accessor :raison, :besoin_contact

  def initialize(raison: nil, besoin_contact: false)
    @raison = raison&.to_sym
    @besoin_contact = besoin_contact
  end

  def raisons_options
    [
      { value: :creneaux, label: "Vous souhaitez prendre un RDV" },
      { value: :annuler, label: "Vous souhaitez annuler votre RDV" },
      { value: :autre, label: "Autre raison" },
    ]
  end

  def raison_creneaux? = raison == :creneaux
  def raison_annuler? = raison == :annuler
  def raison_autre? = raison == :autre
  def besoin_contact? = besoin_contact.present?

  def raison_label = raisons_options.find { _1[:value] == raison }[:label]

  def should_redirect_to_demande_support?
    raison_autre? || besoin_contact?
  end
end
