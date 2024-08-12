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

  def rdv_invitation_token?
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

  def prescribe?
    TerritoryScope.new(pundit_user, User.where(id: @record.id)).resolve.exists?
  end

  class Scope < Scope
    def resolve
      organisation_ids = if current_organisation.present? && current_organisation.territory.visible_users_throughout_the_territory
                           current_organisation.territory.organisation_ids
                         else
                           current_organisation&.id || current_agent.organisation_ids
                         end

      scope.where(id: UserProfile.where("user_profiles.organisation_id": organisation_ids).distinct.select(:user_id))
    end
  end

  # Scope utilisée lors des recherches usager sur tout le territoire (avec résultats tronqués)
  class TerritoryScope < Scope
    def resolve
      # On a un seul territoire pour tous les CNFS, idem pour les mairies,
      # on veut donc *pas* décloisonner la recherche sur tout le territoire.
      if current_organisation.territory.mairies? || current_organisation.territory.cn?
        super
      else
        scope.joins(:territories).where(territories: current_organisation.territory)
      end
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

    authorized_organisation_ids =
      if current_organisation
        if current_organisation.territory.visible_users_throughout_the_territory
          current_organisation.territory.organisation_ids
        else
          [current_organisation.id]
        end
      else
        current_agent.organisation_ids
      end

    @record.user_profiles.map(&:organisation_id).intersect?(authorized_organisation_ids)

    # also, this is not strictly speaking correct. this only checks that the
    # resulting user will belong to the current organisation, but it should also
    # check that you're not making any updates (add or remove) for other
    # organisations.
  end
end
