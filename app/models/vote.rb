class Vote < ApplicationRecord
  belongs_to :votable, polymorphic: true, counter_cache: true

  validates_presence_of :votable

  after_commit  :reindex_children
  before_create :reindex_children

  private

  def reindex_children
    return unless saved_changes.keys.length > 1 # when callback is caused by touch (only updated_at is changed) and there's nothing to reindex
    ReindexChildWorker.perform_async(self.votable.class.name, self.votable.id) if self.votable.present?
  end

end
