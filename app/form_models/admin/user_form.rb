# frozen_string_literal: true

class Admin::UserForm
  include ActiveModel::Model
  include ActiveModel::Cautions
  include ActiveModel::Cautions::Callbacks
  include ActiveModel::Cautions::SafetyDecision

  attr_reader :user

  validate :validate_duplicates
  caution :warn_duplicates

  delegate(:warnings, :errors, to: :user)

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

  def validate_duplicates
    if (duplicate_user = DuplicateUsersFinderService.find_duplicate_based_on_email(user))
      user.errors.add(:base, render_message(duplicate_user))
    end
    duplicate_user.nil?
  end

  def warn_duplicates
    duplicates = DuplicateUsersFinderService.find_duplicate(user)
    duplicates.each { user.warnings.add(:base, render_message(_1), active: true) }
    duplicates.empty?
  end

  def render_message(duplicate_user)
    ApplicationController.render(partial: "admin/users/duplicate_alert", locals: { user: duplicate_user, **@view_locals })
  end
end
