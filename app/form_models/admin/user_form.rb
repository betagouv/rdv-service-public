# frozen_string_literal: true

class Admin::UserForm
  include ActiveModel::Model

  attr_reader :user

  validate :validate_duplicates
  validate :warn_duplicates

  delegate :errors, to: :user

  attr_accessor :active_warnings_confirm_decision

  def warnings_need_confirmation?
    user.errors.keys == [:_warn]
  end

  def initialize(user, active_warnings_confirm_decision: false, view_locals: {})
    @user = user
    self.active_warnings_confirm_decision = active_warnings_confirm_decision
    @view_locals = view_locals
  end

  def valid?
    super && user.valid? # order is important here
  end

  def save
    valid? && user.save
  end

  private

  def duplicate_results
    @duplicate_results ||= DuplicateUsersFinderService.perform_with(user)
  end

  def validate_duplicates
    duplicate_results
      .select { _1.severity == :error }
      .select { _1.attributes.any? { |att| user.send("#{att}_changed?") } }
      .each { user.errors.add(:base, render_message(_1)) }
  end

  def warn_duplicates
    return if active_warnings_confirm_decision

    duplicate_results
      .select { _1.severity == :warning }
      .select { _1.attributes.any? { |att| user.send("#{att}_changed?") } }
      .each { user.errors.add(:_warn, render_message(_1)) }
  end

  def render_message(duplicate_result)
    ApplicationController.render(
      partial: "admin/users/duplicate_alert",
      locals: {
        user: duplicate_result.user,
        attributes: duplicate_result.attributes,
        **@view_locals
      }
    )
  end
end
