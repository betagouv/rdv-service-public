class Admin::UserForm
  include ActiveModel::Model

  attr_reader :user

  validate :validate_duplicates

  delegate :ignore_benign_errors, :ignore_benign_errors=, :add_benign_error, :benign_errors, :not_benign_errors, :errors_are_all_benign?, to: :user
  validate :warn_duplicates
  validate do
    if @user.ants_pre_demande_number.present?
      ValidateAntsPreDemandeNumber.perform(
        user: @user,
        ants_pre_demande_number: @user.ants_pre_demande_number,
        ignore_benign_errors: ignore_benign_errors
      )
    end
  end

  delegate :errors, to: :user

  def initialize(user, ignore_benign_errors: false, view_locals: {})
    @user = user
    self.ignore_benign_errors = ignore_benign_errors
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
    return if ignore_benign_errors

    duplicate_results
      .select { _1.severity == :warning }
      .select { _1.attributes.any? { |att| user.send("#{att}_changed?") } }
      .each { add_benign_error(render_message(_1)) }
  end

  def render_message(duplicate_result)
    ApplicationController.render(
      partial: "admin/users/duplicate_alert",
      locals: {
        user: duplicate_result.user,
        attributes: duplicate_result.attributes,
        **@view_locals,
      }
    )
  end
end
