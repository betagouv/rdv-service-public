class DemandeSupportForm
  include ActiveModel::Model
  attr_accessor :role, :sujet, :first_name, :last_name, :phone, :email, :message

  def initialize(current_domain:, role:, sujet: nil, message: nil)
    @current_domain = current_domain
    @role = role.to_sym
    @sujet = sujet
    @message = message
  end

  def role_usager? = role == :usager
  def role_agent? = role == :agent
end
