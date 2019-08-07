class Front::Products::Questions::FlagsController < Front::FlagsController

  before_action :set_flaggable, only: [ :create ]

  private

  def set_flaggable
    @flaggable = @store.questions.published.find_by_hashid(params[:question_id])
  end
end
