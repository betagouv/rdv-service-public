class ApplicationPolicy
  attr_reader :pundit_user, :record

  def initialize(pundit_user, record)
    @pundit_user = pundit_user
    @record = record
  end

  class Scope
    attr_reader :pundit_user, :scope

    def initialize(pundit_user, scope)
      @pundit_user = pundit_user
      @scope = scope
    end

    def self.apply(pundit_user, scope)
      new(pundit_user, scope).resolve
    end

    def in_scope?(object)
      return false if object&.id.blank?

      resolve.where(id: object.id).any?
    end
  end
end
