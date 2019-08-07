# coding: utf-8
class Front::Products::QuestionsController < FrontController

  before_action :set_product, only: [:index, :show, :new, :create]
  before_action :check_enabled

  def index
    if search_params[:term].nil?
      @questions = @product.questions.published.latest.paginate(page: params[:page], per_page: @store.items_per_page)

      @questions.define_filterable_methods!(
        search_term:  nil,
        filter_value: { status: :published, product_group_ids: [@product.id] },
        sort_mode:    :latest)
    else
      @questions = Question.filtered(
                    current_store: @product.store,
                    term:          search_params[:term],
                    filter_params: { status:            :published,
                                     product_group_ids: [@product.id] },
                    sort:          :latest,
                    page:          params[:page],
                    per_page:      @store.items_per_page
                  )
    end
    respond_to do |format|
      format.html
      format.js
    end
  end

  def show
    @question = @store.questions.published.find_by_hashid(params[:id])

    if @question.present?
      title       = "Q&A - #{@question.product.name}"
      q           = @question.body
      a           = @question.comment.body if @question.comment.present?
      description = "Q: #{ q } #{ '• A: ' + a if a }"
      image       = @question.product.featured_image.url

      set_meta_tags title:         title,
                    description:   description,

                    fb: {
                      app_id:      ENV['FACEBOOK_APP_ID']
                    },

                    og: {
                      title:       title,
                      type:        'website',
                      image:       image,
                      url:         front_product_question_url(@question.store.hashid, @question.product.hashid, @question),
                      description: description
                    },

                    twitter: {
                      card:        'summary',
                      site:        '@HelpfulCrowdApp',
                      title:       title,
                      description: description,
                      image:       image
                    }
    end

    if params[:redirect]
      redirect_to @question.product.url unless browser.bot?
    end

  end

  def new
  end

  def create
    @question         = Question.new(question_params)
    @question.product = @product
    @success          = false

    if !@store.recaptcha_enabled? || verify_recaptcha(model: @question)
      @question.customer = Customer.generate_by_email(@product.store, customer_params[:email], customer_params[:name])

      if @question.save
        BackMailer.pending_question(@question).deliver
        @success = true
      end
    end
    respond_to do |format|
      format.js
    end
  end

  private

  def set_product
    return head(404) unless @store
    @product = @store.products.find_by_id_from_provider_or_hashid(params[:product_id])
  end

  def question_params
    params.require(:question).permit(:body)
  end

  def customer_params
    params.require(:customer).permit(:email, :name)
  end

  def search_params
    params.permit(:term)
  end

  def check_enabled
    not_found unless @store.settings(:questions).enabled.to_b
  end

end
