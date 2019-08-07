class Flag < ApplicationRecord

  belongs_to :flaggable, polymorphic: true

  validates_presence_of :flaggable

  after_create :send_mail

  private

  def send_mail
    BackMailer.flagged_review(self.flaggable).deliver if self.flaggable.is_a?(Review)
    BackMailer.flagged_question(self.flaggable).deliver if self.flaggable.is_a?(Question)
  end

end
