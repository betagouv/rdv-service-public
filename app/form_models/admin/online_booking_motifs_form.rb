class Admin::OnlineBookingMotifsForm
  include ActiveModel::Model

  attr_reader :motif_ids

  def initialize(organisation)
    @organisation = organisation
    @motif_ids = motifs.bookable_by_everyone.pluck(:id)
  end

  def submit(new_motif_ids, flash)
    new_motif_ids ||= []

    motifs_open_before_update = motifs.bookable_by_everyone.any?

    motifs.bookable_by_everyone.where.not(id: new_motif_ids).each do |motif_to_close|
      motif_to_close.update(bookable_by: :agents)
    end

    motifs.where(id: new_motif_ids).each do |motif_to_open|
      motif_to_open.update(bookable_by: :everyone)
    end

    motifs_open_after_update = motifs.bookable_by_everyone.any?

    prepare_flash(flash, motifs_open_before_update, motifs_open_after_update)
  end

  private

  def motifs
    @motifs ||= @organisation.motifs.active
  end

  def prepare_flash(flash, motifs_open_before_update, motifs_open_after_update)
    if motifs_open_before_update
      if motifs_open_after_update
        flash[:success] = "La liste des motifs ouverts à la réservation en ligne a été mise à jour."
      else
        flash[:notice] = "La réservation en ligne a été fermée"
      end
    elsif motifs_open_after_update

      banner = OnlineBookingOnboardingBanner.new(@organisation)

      # Si on affiche la bannière, on ne met pas le flash, parce que ça fait doublon d'avoir une confirmation au dessus du titre et un avertissement sous le titre
      unless banner.display?
        flash[:success] = "Les motifs #{motifs.bookable_by_everyone.pluck(:name).to_sentence} sont ouverts pour la réservation en ligne."
      end
    else
      flash[:error] = "Vous devez choisir au moins un motif pour ouvrir la réservation en ligne"
    end
  end
end
