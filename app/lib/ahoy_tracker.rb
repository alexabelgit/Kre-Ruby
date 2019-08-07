class AhoyTracker

  def initialize(tracker, user)
    @tracker = tracker
    @user = user
  end

  def authenticate
    tracker.authenticate(user)
    self
  end

  def track(action, referrer)
    tracker.track action, user_id: user.id, referrer: referrer
    self
  end

  private

  attr_reader :user, :tracker
end
