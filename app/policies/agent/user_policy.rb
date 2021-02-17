class Agent::UserPolicy < DefaultAgentPolicy
  def show?
    same_org?
  end

  def create?
    # for the creation we want to make sure that all organisation IDs are
    # authorized for the current context (orga or agent)
    return false if @record.user_profiles.empty?

    (
      @record.user_profiles.map(&:organisation_id) -
      (@context.organisation.present? ? [@context.organisation.id] : @context.agent.organisation_ids)
    ).empty?
  end

  def invite?
    create?
  end

  def update?
    same_org?
  end

  def destroy?
    same_org?
  end

  class Scope < Scope
    def resolve
      scope
        .joins(:organisations)
        .where(
          organisations: {
            id: @context.organisation&.id || @context.agent.organisation_ids
          }
        )
    end
  end

  protected

  def same_org?
    # we cannot use @record.organisation_ids for Users because it uses a
    # has_many through: :user_profiles, and `collection_singular_ids` only
    # returns ids for persisted join records so it doesn't work for new records
    # nor updates. we cannot either use pluck for the same reason

    authorized_organisation_ids = \
      if @context.organisation
        [@context.organisation.id]
      else
        @context.agent.organisation_ids
      end
    (@record.user_profiles.map(&:organisation_id) & authorized_organisation_ids).present?

    # also, this is not strictly speaking correct. this only checks that the
    # resulting user will belong to the current organisation, but it should also
    # check that you're not making any updates (add or remove) for other
    # organisations.
  end
end
