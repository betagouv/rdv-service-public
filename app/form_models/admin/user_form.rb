# frozen_string_literal: true

class Admin::UserForm
  include ActiveModel::Model

  attr_reader :user

  delegate :ignore_benign_errors, :ignore_benign_errors=, :add_benign_error, :benign_errors, :not_benign_errors, :errors_are_all_benign?, to: :user

  validate do
    User::Ants.validate_ants_pre_demande_number(
      user: @user,
      ants_pre_demande_number: @user.ants_pre_demande_number,
      ignore_benign_errors: ignore_benign_errors
    )
  end

  delegate :errors, to: :user

  def initialize(user, ignore_benign_errors: false)
    @user = user
    self.ignore_benign_errors = ignore_benign_errors
  end

  def valid?
    super && user.valid? # order is important here
  end

  def save
    valid? && user.save
  end

  def duplicate_results
    @duplicate_results ||= DuplicateUsersFinderService.perform_with(user)
  end
end
