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

  attr_accessor :subject, :first_name, :last_name, :email, :message, :departement, :city

  validates :first_name, :last_name, :email, :message, presence: true
  validates :subject, inclusion: { in: SUBJECTS }
  validates :departement, presence: true, if: -> { subject_role == :agent }
  validates :city, presence: true, if: -> { subject_role == :user }

  def save
    if valid? && Rails.env.production?
      success, api_result = ZammadApi.create_ticket(email, ticket_title, ticket_body)
      errors.add(:base, api_result[:errors].to_sentence) if api_result[:errors]&.any?
      success
    elsif valid?
      puts "\n---\nwould have created zammad ticket with #{email}, #{ticket_title}, #{ticket_body}\n---\n"
      true
    else
      false
    end
  end

  def subject_role
    subject.starts_with?("Je suis usager") ? :user : :agent
  end

  private

  def ticket_title
    [subject, departement, "#{first_name} #{last_name}"].select(&:present?).join(" - ")
  end

  def ticket_body
    {
      Email: email,
      Prénom: first_name,
      Nom: last_name,
      Département: departement,
      Commune: city
    }.select { _2.present? }.map { "#{_1}: #{_2}" }.join("\n") + "\n\n#{message}"
  end
end
