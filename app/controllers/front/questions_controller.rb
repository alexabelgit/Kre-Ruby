class Front::QuestionsController < FrontController

  before_action :check_enabled

  def index
    @questions = @store.recent_questions(page: params[:page])
    @load_more = params[:load_more].present? && params[:load_more].to_b

    title       = 'Q&A'
    description = "List of all Q&A available at #{ @store.name }"
    image       = @store.logo

    set_meta_tags title:         title,
                  description:   description,

                  fb: {
                    app_id:      ENV['FACEBOOK_APP_ID']
                  },

                  og: {
                    title:       title,
                    type:        'website',
                    image:       image,
                    url:         front_questions_url(@store.hashid),
                    description: description
                  },

                  twitter: {
                    card:        'summary',
                    site:        '@HelpfulCrowdApp',
                    title:       title,
                    description: description,
                    image:       image
                  }

    respond_to do |format|
      format.html
      format.js
    end
  end

  private

  def check_enabled
    not_found unless @store.settings(:questions).enabled.to_b
  end

end
