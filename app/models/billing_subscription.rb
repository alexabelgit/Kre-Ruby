class BillingSubscription < ApplicationRecord

  ## Associations
  belongs_to :store

  ## Enums
  enum kind:   [:free_forever, :product_groups, :social_push,      :unlimited_requests, :media_reviews]
  enum status: [:default,      :trialing,       :trial_ended,      :active,
                :soft_failure, :past_due,       :canceled,         :unpaid,
                :expired,      :on_hold,        :assessing,        :pending,
                :suspended,    :paused,         :failed_to_create]

  scope :current,  -> { where(status: %w(pending trialing assessing active soft_failure past_due)) }
  scope :inactive, -> { where.not(status: %w(pending trialing assessing active soft_failure past_due)) }
  scope :renewing, -> { where(cancel_at_end_of_period: false) }
  scope :paid,     -> { where.not(kind: 'free_forever') }
  scope :free,     -> { where(kind: 'free_forever') }
  scope :enabled,  -> { where(disabled: false) }

end