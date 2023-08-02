# frozen_string_literal: true

module AgentRole::AccessLevelChangeable
  extend ActiveSupport::Concern

  def change_role_to_intervenant
    if agent.organisations.count > 1
      errors.add(:base, "Un agent membre de plusieurs organisations ne peut pas avoir un statut d'intervenant")
      return false
    end

    reset_agent_email_and_password
    reset_agent_invitation_fields
    assign_role_from_agent && agent.save
  end

  def change_role_from_intervenant_and_invite(current_agent, invitation_email)
    if invitation_email.blank?
      errors.add(:base, "L'email d'invitation doit être rempli")
      return false
    end

    update_agent_and_confirm(invitation_email) &&
      assign_role_from_agent &&
      agent.invite!(current_agent)
  end

  private

  def update_agent_and_confirm(invitation_email)
    # Devise va essayer de confirmer l'agent car il y a un changement d'email hors on passe d'agent à intervenant, d'un email nil à un email d'invitation.
    # On skip donc la confirmation car on souhaite l'inviter
    agent.skip_confirmation_notification!
    if agent.update(email: invitation_email, uid: invitation_email)
      agent.confirm
      true
    else
      errors.add(:base, agent.errors.full_messages.uniq.to_sentence)
      false
    end
  end

  def assign_role_from_agent
    # A cause des nested attributes nous devons passer par l'agent pour assigner le role car celui ci a des validations contextuels liées aux roles intervenants
    # Sans cela, en sauvegardant l'agent_role simplement, l'agent n'est pas valide car il n'a pas de mail et un role qui n'est pas encore intervenant.
    agent.roles = [self]
  end

  def reset_agent_email_and_password
    agent.email = nil
    agent.uid = nil
    agent.password = nil
    agent.password_confirmation = nil
  end

  def reset_agent_invitation_fields
    agent.invitation_token = nil
    agent.invitation_accepted_at = nil
    agent.invitation_created_at = nil
    agent.invitation_sent_at = nil
    agent.invited_by_id = nil
    agent.invited_by_type = nil
  end
end
