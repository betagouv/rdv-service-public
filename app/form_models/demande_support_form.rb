class DemandeSupportForm
  include ActiveModel::Model
  ATTRIBUTES = %i[current_domain role sujet first_name last_name phone_number email message].freeze
  attr_accessor(*ATTRIBUTES)

  validates(*ATTRIBUTES.excluding(:phone_number), presence: true)
  validates :message, length: { maximum: 3_000 * 3 } # 3 000 caractères ~= 1 page A4
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  def initialize(current_domain:, role: nil, sujet: nil, first_name: nil, last_name: nil, phone_number: nil, email: nil, message: nil)
    @current_domain = current_domain
    @role = role&.to_sym
    @sujet = sujet
    @first_name = first_name
    @last_name = last_name
    @phone_number = phone_number
    @email = email
    @message = message
  end

  def role_usager? = role == :usager
  def role_agent? = role == :agent

  def submit
    return unless valid?

    CreateZammadTicketJob.perform_later(
      sender_role: role,
      email:,
      subject: ticket_subject,
      body: ticket_body,
      tags: [current_domain.to_s]
    )
  end

  private

  def ticket_subject
    "#{sujet} – depuis le formulaire de demande de support"
  end

  # Nous utilisons cette méthode uniquement pour Zammad car Crisp permet de stocker les informations de contact
  # dans les métadonnées de la conversation
  def ticket_body
    <<~BODY
      #{message}

      ---
      Prénom : #{first_name}
      Nom: #{last_name}
      Email: #{email}
      Téléphone: #{phone_number || 'N/A'}

      Message envoyé depuis le formulaire de contact
    BODY
  end
end
