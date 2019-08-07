class Integrations::Ecwid::DashboardController < Integrations::EcwidController

  def index
    current_store = current_user.store

    @reviews   = current_store.reviews.pending
    @questions = current_store.questions.pending
  end

end
