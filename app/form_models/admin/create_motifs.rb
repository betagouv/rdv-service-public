class Admin::CreateMotifs
  include ActiveModel::Validations

  validate :organisations_are_present
  validate :motifs_are_valid

  def initialize(motif_params:, organisations:)
    @motif_params = motif_params
    @organisations = organisations
  end

  def save
    return false if invalid?

    Motif.transaction do
      motifs.each(&:save!)
    end
  end

  def motifs
    @motifs ||= @organisations.map { |org| Motif.new(@motif_params.merge(organisation: org)) }
  end

  def motif_for_form
    motif_for_form = motifs.first.dup
    motif_for_form.organisation = nil
    motif_for_form.errors.clear
    motif_for_form
  end

  private

  def organisations_are_present
    errors.add(:base, "Aucune organisation sélectionnée") if @organisations.empty?
  end

  def motifs_are_valid
    motifs.select(&:invalid?).each do |motif|
      motif.errors.each do |motif_error|
        if motif_error.attribute == :name && motif_error.type == :taken
          errors.add(:base, "Un motif du même nom, même service et même type existe déjà dans #{motif.organisation.name}")
        else
          errors.import(motif_error) unless errors.added?(motif_error.attribute, motif_error.type) # deduplicate errors
        end
      end
    end
  end
end
