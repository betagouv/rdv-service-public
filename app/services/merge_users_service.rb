class MergeUsersService < BaseService
  def initialize(user_target, user_to_merge, attributes_to_merge, organisation)
    @user_target = user_target
    @user_to_merge = user_to_merge
    @attributes_to_merge = attributes_to_merge
    @organisation = organisation
  end

  def perform
    User.transaction do
      merge_user_attributes
      merge_organisations
      merge_rdvs
      merge_relatives
      merge_file_attentes
      merge_referent_agents
      @user_to_merge.reload.soft_delete(@organisation) # ! reload refreshes associations to delete
    end
  end

  private

  def merge_user_attributes
    @attributes_to_merge.each do |attribute|
      @user_target.send("#{attribute}=", @user_to_merge.send(attribute))
    end

    # On évite ici que l'usager cible soit responsable de lui-même.
    # On arrive dans ce cas lorsque l'usager source a pour responsable l'usager cible.
    @user_target.responsible = nil if @user_target.responsible == @user_target

    # Si le user_target s'est déjà connecté avec FranceConnect,
    # les attributs ne sont pas écrasés lors de la fusion
    if @user_to_merge.logged_once_with_franceconnect?
      @user_target.logged_once_with_franceconnect = true
      @user_target.franceconnect_openid_sub = @user_to_merge.franceconnect_openid_sub
    end
    @user_target.save!
  end

  def merge_organisations
    return unless users_visible_through_territory?

    orgs_of_both_users = @user_to_merge.organisations + @user_target.organisations
    orgs_to_move_to_target = orgs_of_both_users.select { _1.territory == @organisation.territory }.uniq
    @user_target.organisations += (orgs_to_move_to_target - @user_target.organisations)
    @user_to_merge.organisations -= orgs_to_move_to_target
  end

  def merge_rdvs
    rdvs_to_merge = if users_visible_through_territory?
                      @user_to_merge.rdvs.where(organisation: Organisation.where(territory: @organisation.territory))
                    else
                      @user_to_merge.rdvs.where(organisation: @organisation)
                    end

    rdvs_to_merge.distinct.each do |rdv|
      rdv.participations.where(user: @user_to_merge).each do |participation|
        if rdv.participations.where(user_id: @user_target).any?
          participation.destroy!
        else
          participation.update!(user: @user_target)
        end
      end
    end
  end

  def merge_relatives
    @user_to_merge.relatives.each do |user_relative|
      user_relative.responsible = @user_target
      user_relative.save!
    end
  end

  def merge_file_attentes
    files_attentes_to_merge = if users_visible_through_territory?
                                @user_to_merge.file_attentes.joins(:rdv).where(rdv: @organisation.territory.rdvs)
                              else
                                @user_to_merge.file_attentes.joins(:rdv).where(rdv: { organisation: @organisation })
                              end

    files_attentes_to_merge.distinct.each do |file_attente_to_merge|
      file_attente_target = @user_target.file_attentes.find_by(rdv: file_attente_to_merge.rdv)
      if file_attente_target
        file_attente_to_merge.destroy
      else
        file_attente_to_merge.update!(user: @user_target)
      end
    end
  end

  def merge_referent_agents
    agents_to_transfer = if users_visible_through_territory?
                           @user_to_merge.referent_agents.merge(@organisation.territory.organisations_agents)
                         else
                           @user_to_merge.referent_agents.merge(@organisation.agents)
                         end

    return unless agents_to_transfer.any?

    @user_to_merge.referent_agents -= agents_to_transfer
    @user_target.referent_agents += (agents_to_transfer - @user_target.referent_agents)
  end

  def users_visible_through_territory?
    @organisation.territory.visible_users_throughout_the_territory
  end
end
