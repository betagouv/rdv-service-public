class Users::RdvBookingForm::SelectedUserParam
  def self.parse(token)
    case token
    when "current_user" then new(:current_user)
    when /\Aexisting_relative_(\d+)\z/ then new(:existing_relative, id: Regexp.last_match(1))
    when /\Anew_relative_(\d+)\z/ then new(:new_relative, index: Regexp.last_match(1).to_i)
    else new(:unknown)
    end
  end

  attr_reader :type, :id, :index

  def initialize(type, id: nil, index: nil)
    @type = type
    @id = id # uniquement pour les existing_relatives
    @index = index # uniquement pour les new_relatives
  end

  def current_user? = type == :current_user
  def existing_relative? = type == :existing_relative
  def new_relative? = type == :new_relative

  def to_s
    case type
    when :current_user
      "current_user"
    when :existing_relative
      "existing_relative_#{id}"
    when :new_relative
      "new_relative_#{index}"
    end
  end
end
