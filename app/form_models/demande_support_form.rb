class DemandeSupportForm
  include ActiveModel::Model
  attr_accessor :role, :raison, :message

  def initialize(current_domain:, role: nil, raison: nil, message: nil)
    @role = role&.to_sym
    @raison = raison&.to_sym
    @message = message
    @current_domain = current_domain
  end

  def method
    display_textarea? ? "POST" : "GET"
  end

  def role_legend = "Votre rôle"
  def raison_legend = "La raison de votre prise de contact"

  def roles_options
    [{ value: "user", label: "Je suis un particulier" }, { value: "agent", label: "Je suis un agent du service public" }]
  end

  def raisons_options
    if role_user?
      [
        { value: :creneaux, label: "Je ne trouve pas de créneaux de RDV" },
        { value: :autre, label: "Autre raison" },
      ]
    elsif role_agent?
      [
        { value: :connexion, label: "Je n’arrive pas à me connecter à mon compte" },
        { value: :autre, label: "Autre raison" },
      ]
    else
      []
    end
  end

  def role_user? = role == :user
  def role_agent? = role == :agent
  def raison_autre? = raison == :autre

  def warning_message
    return nil if role.nil? || raison.nil?

    if @current_domain == Domain::RDV_MAIRIE
      "Nous ne pouvons pas débloquer d'autres créneaux que ceux affichés, nous pouvons seulement aider avec les sujets techniques"
    else
      "Nous ne sommes pas travailleurs médico-sociaux, et nous ne pouvons pas débloquer d'autres créneaux que ceux affichés, nous pouvons seulement aider avec les sujets techniques."
    end
  end

  def display_textarea?
    role_agent? || (role_user? && raison_autre?)
  end

  def display_submit?
    role.nil? || raison.nil? || display_textarea?
  end
end
