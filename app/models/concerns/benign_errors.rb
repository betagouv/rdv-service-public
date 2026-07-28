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
    errors.filter { benign_error?(_1) }.map(&:message)
  end

  def not_benign_errors
    # NOTE: il y a une incohérence de types renvoyés entre les deux méthodes benign_errors et not_benign_errors
    errors.filter { !benign_error?(_1) }
  end

  def errors_are_all_benign?
    errors.any? && errors.all? { benign_error?(_1) }
  end

  private

  # Les erreurs bénignes ajoutées sur un proche (ex: relative.add_benign_error) peuvent être
  # importées par Rails sous la clé "association._benign" (ActiveRecord::Associations::NestedError)
  # lorsque la validation en cascade d'une association imbriquée se déclenche. Il faut les
  # reconnaître comme bénignes elles aussi, pas seulement la clé exacte :_benign.
  def benign_error?(error)
    error.attribute == :_benign || error.attribute.to_s.end_with?("._benign")
  end
end
