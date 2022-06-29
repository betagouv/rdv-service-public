# frozen_string_literal: true

module BenignErrors
  # ActiveModel errors that can be ignored
  #
  # Implements the most basic functionality or activemodel-caution, using ActiveModel::Errors.
  # This does not support attribute-specific errors!
  extend ActiveSupport::Concern

  # This is implemented around the `ignore_benign_errors` flag:
  # * A first submission of a form returns benign errors
  # * The form can be submitted again, with ignore_benign_errors: true to ignore those errors.
  # * The custom validations in models check its value to bypass the validation.
  #
  # See also /app/views/application/_model_errors.html.slim
  attr_accessor :ignore_benign_errors

  def add_benign_error(message)
    errors.add(:_benign, message)
  end

  def benign_errors
    errors[:_benign]
  end

  def not_benign_errors
    # I would like to use ActiveModel::Errors#slice! here, but it relies on making a copy of the Errors.
    errors.filter { |k, _| k.attribute != :_benign }
  end

  def errors_are_all_benign?
    errors.attribute_names == [:_benign]
  end
end
