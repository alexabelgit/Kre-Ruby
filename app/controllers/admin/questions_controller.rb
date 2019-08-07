class Admin::QuestionsController < AdminController
  before_action :set_question, only: [ :show ]

  add_breadcrumb "Admin", :admin_root_path
  add_breadcrumb "Q&A",   :admin_questions_path

  def index
    @questions = Question.includes(:comment, :customer, product: [:store]).order(created_at: :desc)
                         .paginate(page: params[:page], per_page: 100)
  end

  def show
    add_breadcrumb @question.hashid, admin_question_path(@question)
  end

  private

  def set_question
    @question = Question.find_by_hashid(params[:id])
  end
end
