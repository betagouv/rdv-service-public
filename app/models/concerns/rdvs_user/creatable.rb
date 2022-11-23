# frozen_string_literal: true

module RdvsUser::Creatable
  extend ActiveSupport::Concern

  def create_and_notify(author)
    RdvsUser.transaction do
      if save
        notify_create!(author)
        true
      else
        false
      end
    end
  end

  def rdv_user_token
    @notifier&.rdv_users_tokens_by_user_id&.fetch(user.id)
  end

  def notify_create!(author)
    @notifier = Notifiers::RdvCreated.new(rdv, author, [user])
    @notifier&.perform
  end
end
