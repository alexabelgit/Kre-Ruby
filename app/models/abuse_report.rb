class AbuseReport < ApplicationRecord
  ## Associations
  belongs_to :abusable, polymorphic: true

  ## Callbacks
  after_create :send_mail_to_merchant
  after_save   :suppress_abusable
  after_save   :resolve

  ## Delegates
  delegate :store, to: :abusable
  delegate :user, :user_email, to: :store

  ## Enums
  enum reason: { hate_speech:           0,
                 privacy_breach:        1,
                 explicit_content:      2,
                 profanity:             3,
                 mention_of_competitor: 4,
                 misinformation:        5,
                 something_else:        6 }
  # 'reason' is displayed via 'human_enum_name' so any change here needs to be reflected in locales

  enum source: { by_merchant:    0,
                 by_helpful_bot: 1,
                 by_customer:    2 }

  enum status: { open:     0,
                 resolved: 1 }

  enum decision: { pending:  0,
                   accepted: 1,
                   rejected: 2 }

  ## Scopes
  scope :latest, -> { order(created_at: :desc) }

  ## Validations
  validates :reason, presence: true
  validates :source, :abusable_id, :abusable_type, presence: true
  validates :additional_info, presence: { if: -> { something_else? } }

  ## Methods

  def self.decisions_updatable_to
    %w[accepted rejected]
  end

  def inappropriate_content_type
    abusable_type == 'Question' ? 'Q&A' : abusable_type
  end

  private

  def send_mail_to_merchant
    BackMailer.inappropriate_content(self).deliver unless by_merchant?
  end

  def suppress_abusable
    abusable.suppress if saved_change_to_decision? && accepted?
  end

  def resolve
    resolved! if saved_change_to_decision? && !pending? && !resolved?
  end
end
