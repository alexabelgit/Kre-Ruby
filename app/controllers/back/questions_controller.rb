class Back::QuestionsController < BackController

  before_action :set_question, only: [:show, :update]

  def index
    @questions = Question.filtered(current_store: current_store,
                                 term:          search_params[:term],
                                 filter_params: filter_params,
                                 sort:          :by_created_at,
                                 page:          params[:page],
                                 per_page:      5)
  end

  def show

  end

  def update
    return unless Question.statuses_updatable_to.any? {|s| s == question_params[:status]}

    if @question.update_attributes(question_params)

      if @question.archived?
        social_posts_present = true if @question.social_posts.any?
        @question.social_posts.destroy_all

        flash.now[:notice] = (social_posts_present ?
                             'Question was archived and corresponding social posts were unpublished.' :
                             'Question was archived.'), :fade
      elsif @question.published?
        flash.now[:success] = 'Question was published.', :fade
      end

      respond_to do |format|
        if params.has_key?(:app)
          case params[:app]
          when 'ecwid'
            format.html { redirect_to integrations_ecwid_path }
            format.js   { render "integrations/ecwid/questions/update" }
          when 'shopify'
            format.html { redirect_to integrations_shopify_path }
            format.js   { render "integrations/shopify/questions/update" }
          end
        else
          format.html { redirect_to back_questions_path }
          format.js
        end
      end
    else
      respond_to do |format|
        if params.has_key?(:app)
          case params[:app]
          when 'ecwid'
            format.html { render "integrations/ecwid/dashboard/index" }
            format.js   # TODO this should be replaced with appropriate file in integrations/ecwid..
          when 'shopify'
            format.html { render "integrations/shopify/dashboard/index" }
            format.js   # TODO this should be replaced with appropriate file in integrations/shopify..
          end
        else
          format.html { render :show }
          format.js
        end
      end
    end
  end

  private

  def set_question
    @question = current_store.questions.find_by_hashid(params[:id])
  end

  def question_params
    params.require(:question).permit(:status)
  end

  def filter_params
    params.permit(:status, :product_id, :product_group_ids)
  end

  def search_params
    params.permit(:term)
  end
end
