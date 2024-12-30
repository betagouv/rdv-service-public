class DemandeSupportForm
  include ActiveModel::Model
  attr_accessor :raison, :message, :besoin_contact

  def initialize(current_domain:, raison: nil, message: nil)
    @raison = raison&.to_sym
    @message = message
    @current_domain = current_domain
  end

  def method
    display_textarea? ? "POST" : "GET"
  end

  def raison_legend = "La raison pour laquelle vous nous contactez"

  def raisons_options
    [
      { value: :creneaux, label: "Je ne trouve pas de créneaux de RDV" },
      { value: :annuler, label: "Je n’arrive pas à annuler mon RDV" },
      { value: :autre, label: "Autre raison" },
    ]
  end

  def raison_creneaux? = raison == :creneaux
  def raison_annuler? = raison == :annuler
  def raison_autre? = raison == :autre

  def display_textarea? = raison_autre?

  def display_submit?
    raison.nil? || display_textarea?
  end
end
