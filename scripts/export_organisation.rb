# bundle exec rails runner scripts/export_organisation.rb eer53d 1

class Exporter
  def initialize(dump_id, organisation_id)
    @organisation_id = organisation_id.to_i
    puts "@organisation_id is #{@organisation_id}"
    @dump_path = Rails.root + "tmp/dump_#{dump_id}"
  end

  def export
    FileUtils.mkdir_p(@dump_path)
    puts "outputting to #{@dump_path}..."

    Organisation.where(id: @organisation_id).copy_to(output("organisations"))
    User.joins(:user_profiles).where(user_profiles: { organisation_id: @organisation_id }).copy_to(output("users"))
    Rdv.where(organisation_id: @organisation_id).copy_to(output("rdvs"))

    puts "done!"
  end

  protected

  def output(name)
    "#{@dump_path}/#{name}.csv"
  end
end

Exporter.new(ARGV[0], ARGV[1]).export
