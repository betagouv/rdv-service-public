class ZammadCustomer
  include ActiveModel::Model # provides the convenient initializer
  include ActiveModel::Attributes # lets us declare attributes easily

  attribute :email, :string
  attribute :firstname, :string
  attribute :lastname, :string
  attribute :phone, :string
  attribute :super_admin_url, :string
  attribute :note, :string
  attribute :rdvsp_role, :string
  attribute :instance, :string, default: Domain.default_domain_for_current_instance.to_s
end
