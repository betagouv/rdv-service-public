class DemandeSupportForm
  include ActiveModel::Model
  ATTRIBUTES = %i[current_domain role sujet first_name last_name phone_number email message user_id agent_id].freeze
  attr_accessor(*ATTRIBUTES)

  validates(*ATTRIBUTES.excluding(:phone_number, :user_id, :agent_id), presence: true)
  validates :message, length: { maximum: 3_000 * 3 } # 3 000 caractères ~= 1 page A4
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  def initialize(current_domain:, role: nil, sujet: nil, first_name: nil, last_name: nil, phone_number: nil, email: nil, message: nil, user_id: nil, agent_id: nil)
    @current_domain = current_domain
    @role = role&.to_sym
    @sujet = sujet
    @first_name = first_name
    @last_name = last_name
    @phone_number = phone_number
    @email = email
    @message = message
    @user_id = user_id
    @agent_id = agent_id
  end

  def role_usager? = role == :usager
  def role_agent? = role == :agent

  def submit
    return unless valid?

    CreateZammadTicketJob.perform_later(
      sender_role: role,
      email:,
      first_name:,
      last_name:,
      phone_number:,
      user_id:,
      agent_id:,
      subject: sujet,
      body: ticket_body,
      tags: [current_domain.to_s, "Formulaire Demande Support"]
    )
  end

  private

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
