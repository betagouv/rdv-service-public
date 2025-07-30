class Notifiers::PlageOuvertureBase < BaseService
  def initialize(plage_ouverture)
    @plage_ouverture = plage_ouverture
  end

  def perform
    notify if agent_notifiable?
  end

  private

  def notify
    raise NotImplementedError, "Subclasses must implement the notify method"
  end

  def agent_notifiable?
    @plage_ouverture.agent&.email.present?
  end
end
