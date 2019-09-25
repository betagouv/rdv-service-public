class ProPolicy < AdminPolicy
  def show?
    same_pro_or_admin?
  end

  def edit?
    same_pro_or_admin?
  end

  def destroy?
    same_pro_or_admin?
  end

  def invite?
    admin_and_belongs_to_record_organisation?
  end

  def reinvite?
    invite?
  end

  private

  def same_pro_or_admin?
    @pro == @record || admin_and_belongs_to_record_organisation?
  end
end
