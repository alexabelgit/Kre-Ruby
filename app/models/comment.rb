class Comment < ApplicationRecord

  include Abusable

  before_create :mask_email_in_body, :reindex_children
  after_commit  :reindex_children

  belongs_to :user
  belongs_to :commentable, polymorphic: true

  has_many :emails,        as: :emailable, dependent: :destroy
  has_many :abuse_reports, as: :abusable,  dependent: :destroy

  delegate :store, to: :commentable
  delegate :display_initials, to: :user
  delegate :display_logo, to: :store

  validates_presence_of   :body,             :commentable,           :display_name
  validates_length_of     :body,             minimum: 1,             maximum: 6000
  validates_uniqueness_of :commentable_type, scope: :commentable_id

  attr_accessor :skip_reindex_children

  def send_comment_mail
    if can_send?
      uid = SecureRandom.uuid
      response = FrontMailer.send("comment_on_#{commentable.class.name.downcase}", self.id, uid).deliver!
      self.emails.create(helpful_id: uid, :'smtp-id' => response.message_id, address: response.to_addrs) if response
    end
  end

  def verified?
    true # This needs to be updated when we allow comments from customers
  end

  def can_send?
    self.commentable.customer.present? && !self.commentable.customer.suppressed?
  end

  def self.abusable_fields
    return ['body']
  end

  def suppress
    return
  end

  private

  def mask_email_in_body
    self.body = self.body.mask_email
  end

  def reindex_children
    return unless saved_changes.keys.length > 1 # when callback is caused by touch (only updated_at is changed) and there's nothing to reindex
    unless @skip_reindex_children
      ReindexChildWorker.perform_async(self.commentable.class.name, self.commentable.id) if self.commentable.present?
    end
    @skip_reindex_children = false
  end
end
