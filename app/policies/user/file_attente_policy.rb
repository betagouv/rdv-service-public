class User::FileAttentePolicy < ApplicationPolicy
  alias current_user pundit_user

  def create_or_delete?
    file_attente_belongs_to_user_or_relatives? && rdv_belongs_to_user_or_relatives?
  end

  private

  def file_attente_belongs_to_user_or_relatives?
    current_user.available_users_for_rdv.pluck(:id).include?(record.user_id)
  end

  def rdv_belongs_to_user_or_relatives?
    record.rdv.present? && record.rdv.user_ids.intersect?(current_user.available_users_for_rdv.pluck(:id))
  end
end
