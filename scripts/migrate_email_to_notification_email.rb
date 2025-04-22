#!/usr/bin/env ruby
# Ce script migre les emails des utilisateurs de RDV-Insertion vers le champ notification_email
# Il sélectionne les utilisateurs qui:
# - Appartiennent uniquement à des organisations avec verticale 'rdv_insertion'
# - N'utilisent pas le système d'authentification
# - Ont un email mais pas de notification_email
# Usage: bundle exec rails runner scripts/migrate_email_to_notification_email.rb

require "benchmark"
require "fileutils"

class EmailToNotificationEmailMigrator
  def initialize
    @log_file = "log/email_migration_#{Time.current.strftime('%Y%m%d_%H%M%S')}.log"
    @migrated_users_file = "log/email_migration_#{Time.current.strftime('%Y%m%d_%H%M%S')}_migrated_users_ids.log"
    @stats = {
      total_rdv_insertion_users: 0,
      eligible_for_migration: 0,
      migrated_users: 0,
      errored_users: 0,
    }

    FileUtils.mkdir_p(File.dirname(@log_file))
    @logger = File.open(@log_file, "w")
    log("Démarrage de la migration - #{Time.current}")
  end

  def perform
    time = Benchmark.measure do
      analyze_users
      migrate_users
    end

    log_stats(time)
    @logger.close
    puts "Migration terminée. Logs disponibles dans: #{@log_file}"
    puts "Liste des IDs utilisateurs migrés disponible dans: #{@migrated_users_file}"
  end

  private

  def analyze_users
    log("Sélection des usagers appartenant uniquement aux organisations avec verticale 'rdv_insertion'")

    @rdv_insertion_users = find_users_with_only_rdv_insertion_organisations
    @stats[:total_rdv_insertion_users] = @rdv_insertion_users.count
    log("Total d'utilisateurs avec uniquement des organisations rdv_insertion: #{@stats[:total_rdv_insertion_users]}")

    @users_to_migrate = select_eligible_users(@rdv_insertion_users)
    @stats[:eligible_for_migration] = @users_to_migrate.count
    log("Utilisateurs éligibles pour la migration: #{@stats[:eligible_for_migration]}")
  end

  def migrate_users
    return if @users_to_migrate.empty?

    log("Début de la migration des emails vers notification_email")
    processed = 0
    @users_to_migrate.find_in_batches(batch_size: 1000) do |users_batch|
      processed += users_batch.size
      log("Traitement: #{processed}/#{@stats[:eligible_for_migration]} utilisateurs (#{(processed.to_f / @stats[:eligible_for_migration] * 100).round(1)}%)...")

      users_batch.each do |user|
        email = user.email
        user.update_columns(
          notification_email: email,
          email: nil,
          updated_at: Time.current
        )
        @stats[:migrated_users] += 1
        File.open(@migrated_users_file, "a") do |f|
          f.puts(user.id)
        end
      rescue StandardError => e
        log("ERREUR pour l'utilisateur ##{user.id}: #{e.message}", :error)
        @stats[:errored_users] += 1
      end
    end
  end

  def find_users_with_only_rdv_insertion_organisations
    users_with_rdv_insertion = User.joins(user_profiles: :organisation)
      .where(organisations: { verticale: "rdv_insertion" })
      .distinct

    users_with_mixed_verticales = User.joins(user_profiles: :organisation)
      .where(id: users_with_rdv_insertion.select(:id))
      .where.not(organisations: { verticale: "rdv_insertion" })
      .distinct

    User.where(id: users_with_rdv_insertion.select(:id))
      .where.not(id: users_with_mixed_verticales.select(:id))
  end

  def select_eligible_users(base_users)
    # - avec un email non vide
    # - sans notification_email
    # - non-connectés (pas de confirmed_at, pas de mot de passe, pas de franceconnect)
    base_users.where.not(email: [nil, ""])
      .where(notification_email: [nil, ""])
      .where(confirmed_at: nil)
      .where(encrypted_password: ["", nil])
      .where(logged_once_with_franceconnect: [nil, false])
  end

  def log(message, level = :info)
    timestamp = Time.current.strftime("%Y-%m-%d %H:%M:%S")
    prefix = case level
             when :error then "[ERREUR] "
             when :info then "[INFO] "
             else ""
             end

    log_message = "#{timestamp} #{prefix}#{message}"
    @logger.puts(log_message)
    @logger.flush

    puts log_message if level == :error
  end

  def log_stats(time)
    log("Migration terminée en #{time.real.round(2)} secondes")
    log("Statistiques:")
    log("  - Total d'utilisateurs RDV-Insertion: #{@stats[:total_rdv_insertion_users]}")
    log("  - Utilisateurs éligibles pour migration: #{@stats[:eligible_for_migration]}")
    log("  - Utilisateurs migrés avec succès: #{@stats[:migrated_users]}")
    log("  - Erreurs lors de la migration: #{@stats[:errored_users]}")
  end
end

if $PROGRAM_NAME == __FILE__
  migrator = EmailToNotificationEmailMigrator.new
  migrator.perform
end
