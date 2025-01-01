class DemandeSupportForm
  include ActiveModel::Model
  ATTRIBUTES = %i[role sujet first_name last_name phone_number email message].freeze
  attr_accessor(*ATTRIBUTES)

  validates(*ATTRIBUTES.excluding(:phone_number), presence: true)

  def initialize(current_domain:, role:, sujet: nil, first_name: nil, last_name: nil, phone_number: nil, email: nil, message: nil)
    @current_domain = current_domain
    @role = role.to_sym
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

    ZammadApiClient.create_ticket(
      sender_role: role,
      email:,
      subject: ticket_subject,
      body: ticket_body
    )
  end

  private

  def ticket_subject
    "Demande Support #{role.to_s.capitalize} - #{first_name} #{last_name} - #{sujet}"
  end

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
