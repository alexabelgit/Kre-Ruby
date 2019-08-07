class OnboardingChannel < ApplicationCable::Channel

  def subscribed
    stream_from "onboarding-#{current_user.hashid}"
  end

end
