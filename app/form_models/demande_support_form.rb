class DemandeSupportForm
  include ActiveModel::Model
  attr_accessor :raison, :message, :besoin_contact

  def initialize(current_domain:, raison: nil, message: nil, besoin_contact: false)
    @current_domain = current_domain
    @raison = raison&.to_sym
    @message = message
    @besoin_contact = besoin_contact
  end

  def method
    display_message_form? ? "POST" : "GET"
  end

  def raison_legend = "La raison pour laquelle vous nous contactez"

  def raisons_options
    [
      { value: :creneaux, label: "Vous ne trouvez pas de créneaux disponibles" },
      { value: :annuler, label: "Vous n’arrivez pas à annuler votre RDV" },
      { value: :autre, label: "Autre raison" },
    ]
  end

  def raison_creneaux? = raison == :creneaux
  def raison_annuler? = raison == :annuler
  def raison_autre? = raison == :autre
  def besoin_contact? = besoin_contact.present?

  def raison_label = raisons_options.find { _1[:value] == raison }[:label]

  def display_message_form?
    raison_autre? || besoin_contact?
  end
end
