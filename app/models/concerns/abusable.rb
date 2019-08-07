module Abusable
  extend ActiveSupport::Concern

  included do
    after_commit :check_for_abusable_fields_change
  end

  def report_abuse
    report_abuse_by_helpful_bot(store.settings(:abuse_filters).profanity, :profanity)
    report_abuse_by_helpful_bot(store.settings(:abuse_filters).competitors, :mention_of_competitor)
  end

  def check_for_abuse
    CheckForAbuseWorker.perform_async(self.class.name, id) if has_abuse_filters?
  end

  protected

  def check_for_abusable_fields_change
    check_for_abuse if (saved_changes.keys & self.class.abusable_fields).any?
  end

  def has_abuse_filters?
    return store.settings(:abuse_filters).profanity.split(',').any? || store.settings(:abuse_filters).competitors.split(',').any?
  end

  def report_abuse_by_helpful_bot(filters, reason)
    self.class.abusable_fields.each do |field|
      next unless filters.split(',').any? { |word| send(field).downcase.include?(word.strip.downcase) }
      if reason == :mention_of_competitor && respond_to?(:positive?) && positive?
        AbuseReport.create(abusable: self, reason: reason, source: :by_helpful_bot)
      else
        AbuseReport.create(abusable: self, reason: reason, source: :by_helpful_bot, decision: :accepted)
      end
      return
    end
  end
end
