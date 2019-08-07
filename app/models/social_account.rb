class SocialAccount < ApplicationRecord
  belongs_to :user, touch: true

  validates_uniqueness_of :provider, scope: :user_id

  enum provider: [:facebook, :instagram, :pinterest, :twitter]
end
