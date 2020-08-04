# bundle exec rails runner scripts/import_organisation.rb eer53d

class Importer
  def initialize(dump_id)
    @dump_path = Rails.root + "tmp/dump_#{dump_id}"
  end

  def import
    Organisation.copy_from("#{@dump_path}/organisations.csv")
    # Rdv.copy_from(@dump_path + "/rdvs.csv")
    # User.copy_from(@dump_path + "/users.csv")
  end

  protected

  def input(name)
    "#{@dump_path}/#{name}.csv"
  end
end

Importer.new(ARGV[0]).import
