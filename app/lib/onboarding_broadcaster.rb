class OnboardingBroadcaster
  attr_reader :store

  def initialize(store)
    @store = store
  end

  def broadcast(partial, name, locals: {})
    locals[:store] = store

    view = ApplicationController.renderer.render partial: partial, locals: locals
    ActionCable.server.broadcast broadcast_url, view: view, object: name
  end

  def broadcast_url
    "onboarding-#{store.user.hashid}"
  end
end