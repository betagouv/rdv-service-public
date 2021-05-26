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
      merge_user_profiles
      merge_file_attentes
      merge_agents
      @user_to_merge.reload.soft_delete(@organisation) # ! reload refreshes associations to delete
    end
  end

  private

  def merge_user_attributes
    user_attributes_to_merge.each do |attribute|
      @user_target.send("#{attribute}=", @user_to_merge.send(attribute))
    end
    @user_target.save!
  end

  def merge_rdvs
    @user_to_merge.rdvs.where(organisation: @organisation).each do |rdv|
      users = rdv.users.to_a
      users.delete(@user_to_merge)
      users.append(@user_target) unless users.include?(@user_target)
      rdv.users.replace(users)
    end
  end

  def merge_relatives
    @user_to_merge.relatives.each do |user_relative|
      user_relative.responsible = @user_target
      user_relative.save!
    end
  end

  def merge_user_profiles
    user_profile_to_merge = @user_to_merge.profile_for(@organisation)
    user_profile_target = @user_target.profile_for(@organisation)
    raise if user_profile_target.nil? || user_profile_to_merge.nil?

    user_profile_attributes_to_merge.each do |attribute|
      user_profile_target.send("#{attribute}=", user_profile_to_merge.send(attribute))
    end
    user_profile_target.save!
  end

  def merge_file_attentes
    @user_to_merge.file_attentes.for_organisation(@organisation).each do |file_attente_to_merge|
      file_attente_target = @user_target.file_attentes.find_by(rdv: file_attente_to_merge.rdv)
      if file_attente_target
        file_attente_to_merge.destroy
      else
        file_attente_to_merge.update!(user: @user_target)
      end
    end
  end

  def merge_agents
    return unless @user_to_merge.agents.within_organisation(@organisation).any?

    agents = (
      @user_target.agents.to_a +
      @user_to_merge.agents.within_organisation(@organisation).to_a
    ).uniq
    @user_target.update!(agents: agents)
  end

  def user_attributes_to_merge
    @attributes_to_merge.without(:logement, :notes)
  end

  def user_profile_attributes_to_merge
    @attributes_to_merge.select{ %i[logement notes].include?(_1) }
  end
end
