# frozen_string_literal: true

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
      merge_rdvs
      merge_relatives
      merge_file_attentes
      merge_agents
      @user_to_merge.reload.soft_delete(@organisation) # ! reload refreshes associations to delete
    end
  end

  private

  def merge_user_attributes
    @attributes_to_merge.each do |attribute|
      @user_target.send("#{attribute}=", @user_to_merge.send(attribute))
    end

    # Si le user_target s'est déjà connecté avec FranceConnect,
    # les attributs ne sont pas écrasés lors de la fusion
    if @user_to_merge.logged_once_with_franceconnect?
      @user_target.logged_once_with_franceconnect = true
      @user_target.franceconnect_openid_sub = @user_to_merge.franceconnect_openid_sub
    end
    @user_target.save!
  end

  def merge_rdvs
    @user_to_merge.rdvs.where(organisation: @organisation).each do |rdv|
      rdv.rdvs_users.where(user: @user_to_merge).each do |rdv_user|
        if rdv.rdvs_users.where(user_id: @user_target).any?
          rdv_user.destroy!
        else
          rdv_user.update!(user: @user_target)
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
    @user_to_merge.file_attentes
      .joins(:rdv).where(rdvs: { organisation: @organisation })
      .each do |file_attente_to_merge|
        file_attente_target = @user_target.file_attentes.find_by(rdv: file_attente_to_merge.rdv)
        if file_attente_target
          file_attente_to_merge.destroy
        else
          file_attente_to_merge.update!(user: @user_target)
        end
      end
  end

  def merge_agents
    return unless @user_to_merge.agents.merge(@organisation.agents).any?

    agents = (
      @user_target.agents.to_a +
      @user_to_merge.agents.merge(@organisation.agents).to_a
    ).uniq
    @user_target.update!(agents: agents)
  end
end
