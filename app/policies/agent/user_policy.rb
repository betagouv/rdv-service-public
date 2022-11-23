# frozen_string_literal: true

class Agent::UserPolicy < DefaultAgentPolicy
  def show?
    same_org? && not_deleted?
  end

  def create?
    # Un agent est toujours autorisé à créer un usager.
    # Il y a des contraintes sur l'association à une organisation,c'est sur le `user_profile`,
    # lié au système d'erreur et de contrainte `ActiveRecord`, et non aux authorisation.
    true
  end

  def invite?
    same_org? && not_deleted?
  end

  def update?
    same_org? && not_deleted?
  end

  def destroy?
    same_org? && not_deleted?
  end

  def versions?
    admin_and_same_org? && not_deleted?
  end

  class Scope < Scope
    def resolve
      scope
        .joins(:organisations)
        .where(
          organisations: {
            id: current_organisation&.id || current_agent.organisation_ids,
          }
        )
    end
  end

  protected

  def not_deleted?
    @record.deleted_at.nil?
  end

  def same_org?
    # we cannot use @record.organisation_ids for Users because it uses a
    # has_many through: :user_profiles, and `collection_singular_ids` only
    # returns ids for persisted join records so it doesn't work for new records
    # nor updates. we cannot either use pluck for the same reason

    authorized_organisation_ids = \
      if current_organisation
        [current_organisation.id]
      else
        current_agent.organisation_ids
      end
    (@record.user_profiles.map(&:organisation_id) & authorized_organisation_ids).present?

    # also, this is not strictly speaking correct. this only checks that the
    # resulting user will belong to the current organisation, but it should also
    # check that you're not making any updates (add or remove) for other
    # organisations.
  end
end
