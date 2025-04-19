#!/usr/bin/env ruby
# Ce script migre les emails des utilisateurs de RDV-Insertion vers le champ notification_email
# Il ignore les utilisateurs qui ont activé leur compte Devise (confirmed_at n'est pas nil)
# ou utilisent le système d'authentification (encrypted_password n'est pas vide ou franceconnect est activé)
# Usage: bundle exec rails runner scripts/migrate_email_to_notification_email.rb PATH_TO_USER_IDS_FILE

require "benchmark"
require "fileutils"

class EmailToNotificationEmailMigrator
  def initialize(user_ids_file)
    @user_ids_file = user_ids_file
    @log_file = "log/email_migration_#{Time.current.strftime('%Y%m%d_%H%M%S')}.log"
    @stats = {
      total_users: 0,
      migrated_users: 0,
      errored_users: 0,
      skipped_users_email_and_notification_email_blank: 0,
      skipped_users_email_blank: 0,
      skipped_users_devise: 0,
      skipped_users_notification_email_present: 0,
    }

    FileUtils.mkdir_p(File.dirname(@log_file))
    @logger = File.open(@log_file, "w")
    log("Démarrage de la migration - #{Time.current}")
  end

  def perform
    unless File.exist?(@user_ids_file)
      log("Fichier d'IDs non trouvé: #{@user_ids_file}", :error)
      return
    end

    user_ids = File.readlines(@user_ids_file).map(&:strip).map(&:to_i)

    if user_ids.empty?
      log("Aucun ID d'utilisateur valide trouvé dans le fichier. Opération annulée.", :error)
      return
    end

    time = Benchmark.measure do
      log("Début de la migration des emails vers notification_email")
      log("Traitement de #{user_ids.size} usagers depuis le fichier: #{@user_ids_file}")

      users_scope = User.where(id: user_ids)

      users_scope.find_in_batches(batch_size: 1000) do |users_batch|
        @stats[:total_users] += users_batch.size

        log("Progression: #{@stats[:total_users]} utilisateurs traités") if @stats[:total_users] % 10000 == 0

        users_batch.each do |user|
          migrate_user(user)
        end
      end
    end

    log_stats(time)

    @logger.close

    puts "Migration terminée. Logs disponibles dans: #{@log_file}"
  end

  private

  def migrate_user(user)
    if user.email.blank? && user.notification_email.blank?
      log("Utilisateur ##{user.id} ignoré: email et notification_email manquants", :debug)
      @stats[:skipped_users_email_and_notification_email_blank] += 1
      return
    end

    if user.email.blank?
      log("Utilisateur ##{user.id} ignoré: email manquant", :debug)
      @stats[:skipped_users_email_blank] += 1
      return
    end

    if uses_devise?(user)
      log("Utilisateur ##{user.id} ignoré: utilise Devise", :debug)
      @stats[:skipped_users_devise] += 1
      return
    end

    if user.notification_email.present?
      log("Utilisateur ##{user.id} ignoré: notification_email déjà présent (#{user.notification_email})", :debug)
      @stats[:skipped_users_notification_email_present] += 1
      return
    end

    begin
      email = user.email
      user.update_columns(
        notification_email: email,
        email: nil,
        updated_at: Time.current
      )

      log("Utilisateur ##{user.id} migré: #{email} -> notification_email", :info)
      @stats[:migrated_users] += 1
    rescue StandardError => e
      log("ERREUR pour l'utilisateur ##{user.id}: #{e.message}", :error)
      @stats[:errored_users] += 1
    end
  end

  def uses_devise?(user)
    user.confirmed_at.present? ||
      user.encrypted_password.present? ||
      user.logged_once_with_franceconnect == true
  end

  def log(message, level = :info)
    timestamp = Time.current.strftime("%Y-%m-%d %H:%M:%S.%L")

    prefix = case level
             when :error then "[ERROR] "
             when :info then "[INFO] "
             when :debug then "[DEBUG] "
             else ""
             end

    log_message = "#{timestamp} #{prefix}#{message}"
    @logger.puts(log_message)
    @logger.flush # S'assurer que les logs sont écrits immédiatement

    puts log_message if level == :error
  end

  def log_stats(time)
    log("Migration terminée en #{time.real.round(2)} secondes")
    log("Statistiques:")
    log("  - Total d'utilisateurs traités: #{@stats[:total_users]}")
    log("  - Utilisateurs ignorés: #{@stats[:skipped_users]}")
    log("  - Utilisateurs migrés: #{@stats[:migrated_users]}")
    log("  - Erreurs: #{@stats[:errored_users]}")
    log("  - Utilisateurs ignorés: email et notification_email manquants: #{@stats[:skipped_users_email_and_notification_email_blank]}")
    log("  - Utilisateurs ignorés: email manquant: #{@stats[:skipped_users_email_blank]}")
    log("  - Utilisateurs ignorés: utilise Devise: #{@stats[:skipped_users_devise]}")
    log("  - Utilisateurs ignorés: notification_email déjà présent: #{@stats[:skipped_users_notification_email_present]}")
  end
end

if $PROGRAM_NAME == __FILE__
  user_ids_file = ARGV[0]

  if user_ids_file.nil?
    puts "🔴 ERREUR: Veuillez spécifier le chemin du fichier contenant les IDs d'utilisateurs."
    puts "Usage: bundle exec rails runner scripts/migrate_email_to_notification_email.rb PATH_TO_USER_IDS_FILE"
    exit 1
  end

  migrator = EmailToNotificationEmailMigrator.new(user_ids_file)
  migrator.perform
end
