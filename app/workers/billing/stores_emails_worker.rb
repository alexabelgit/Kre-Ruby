require 'sidekiq-scheduler'

module Billing
  class StoresEmailsWorker
    include Sidekiq::Worker
    sidekiq_options queue: :default

    def perform
      send_trial_ending_emails
      send_trial_finished_emails
      send_grace_period_ended_emails

      send_plan_exceeding_emails
      send_plan_exceeded_emails

      send_miss_you_emails
      send_store_deleted_emails
    end

    private

    def send_trial_ending_emails
      Store.need_send_trial_ending_email.each do |store|
        BackMailer.trial_ending(store.id).deliver
        store.update_settings :billing, trial_ending_email_sent: true
      end
    end

    def send_trial_finished_emails
      Store.need_send_trial_finished_email.each do |store|
        BackMailer.trial_finished(store.id).deliver
        store.update_settings :billing, trial_finished_email_sent: true
      end
    end

    def send_grace_period_ended_emails
      Store.need_send_grace_period_email.each do |store|
        BackMailer.grace_period_ended(store.id).deliver
        store.update_settings :billing, grace_period_email_sent: true
      end
    end

    def send_miss_you_emails
      Store.need_send_miss_you_email.each do |store|
        BackMailer.miss_you(store.id).deliver
        store.update_settings :billing, miss_you_email_sent: true
      end
    end

    def send_plan_exceeding_emails
      Store.need_send_plan_exceeding_email.each do |store|
        BackMailer.plan_exceeding(store.id).deliver
        store.update_settings :billing, plan_exceeding_email_sent: true
      end
    end

    def send_plan_exceeded_emails
      Store.need_send_plan_exceeded_email.each do |store|
        BackMailer.plan_exceeded(store.id).deliver
        store.update_settings :billing, plan_exceeded_email_sent: true
      end
    end

    def send_store_deleted_emails
      Store.need_send_deleted_email.each do |store|
        BackMailer.store_deleted(store.id).deliver
        store.update_settings :billing, store_deleted_email_sent: true
      end
    end
  end
end
