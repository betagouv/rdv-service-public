class SupportTicketForm
  include ActiveModel::Model

  SUBJECTS = [
    "Je suis usager et je n'arrive pas à annuler mon RDV",
    "Je suis usager et je n'arrive pas à accéder à mon compte",
    "Je suis agent et je n'arrive pas à accéder à mon compte",
    "Je suis agent et j'ai une question ou je rencontre un problème",
    "Je suis agent ou décideur public et j'aimerais plus d'informations sur RDV-Solidarités",
    "Autre",
  ].freeze

  attr_accessor :subject, :first_name, :last_name, :email, :message, :departement

  validates :first_name, :last_name, :email, :message, :departement, presence: true

  validates :subject, inclusion: { in: SUBJECTS }

  def save
    if valid?
      success, api_result = ZammadApi.create_ticket(email, ticket_title, ticket_body)
      errors.add(:base, api_result[:errors].to_sentence) if api_result[:errors]&.any?
      success
    else
      false
    end
  end

  private

  def ticket_title
    "#{subject} - #{departement} - #{first_name} #{last_name}"
  end

  def ticket_body
    """Prénom: #{first_name}\nNom: #{last_name}\nDépartement: #{departement}\n\n" + message
  end
end
