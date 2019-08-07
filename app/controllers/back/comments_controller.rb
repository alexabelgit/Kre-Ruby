class Back::CommentsController < BackController

  before_action :set_comment, only: [:edit, :update, :destroy]

  def create
    @comment              = Comment.new(comment_params)
    @comment.commentable  = @commentable
    @comment.user         = current_user
    @comment.display_name = current_store.settings(:agents).default_name unless comment_params.has_key?(:display_name)

    commentable_previous_status = @commentable.status.to_s

    if @comment.save
      @commentable.update_attributes(status: @commentable.class.statuses[:published])
      @comment.send_comment_mail

      if commentable_previous_status == 'published'
        flash.now[:success] = "#{ @commentable.class.name } answered. We will now notify the customer.", :fade
      else
        flash.now[:success] = "#{ @commentable.class.name } answered and published. We will now notify the customer.", :fade
      end

      respond_to do |format|
        if params.has_key?(:app)
          case params[:app]
          when 'ecwid'
            format.html { redirect_to integrations_ecwid_path }
            format.js   { render "integrations/ecwid/comments/create" }
          when 'shopify'
            format.html { redirect_to integrations_shopify_path }
            format.js   { render "integrations/shopify/comments/create" }
          end
        else
          format.html { redirect_to @commentable }
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
          format.html { render :new }
          format.js
        end
      end
    end
  end

  def edit
    respond_to do |format|
      format.html
      format.js
    end
  end

  def update
    flash.now[:success] = "Comment updated", :fade
    if @comment.update_attributes(comment_params)
      respond_to do |format|
        format.html { redirect_to @commentable }
        format.js
      end
    else
      respond_to do |format|
        format.html { render :edit }
        format.js
      end
    end
  end

  def destroy
    flash.now[:success] = "Comment deleted", :fade
    if @comment.destroy
      respond_to do |format|
        format.html { redirect_to @commentable }
        format.js
      end
    else
      respond_to do |format|
        format.html { render :show }
        format.js
      end
    end
  end

  private

  def set_comment
    @comment = current_store.comments.find_by_hashid(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:body, :display_name)
  end

end
