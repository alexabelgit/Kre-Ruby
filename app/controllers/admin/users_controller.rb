class Admin::UsersController < AdminController
  def index
    @search_term = search_params[:term]
    if @search_term.present?
      @users =
        User.where("lower(first_name) LIKE lower('%#{@search_term}%') OR
                    lower(last_name) LIKE lower('%#{@search_term}%') OR
                    lower(email) LIKE lower('%#{@search_term}%')").
        order(created_at: :desc).paginate(page: params[:page], per_page: 20)
    else
      @users = User.order(created_at: :desc).paginate(page: params[:page], per_page: 10)
    end
  end

  def impersonate
    user = User.find(params[:id])
    impersonate_user(user)
    redirect_to root_path
  end

  def stop_impersonating
    stop_impersonating_user
    redirect_to admin_stores_path
  end

  def deactivate
    user = User.find(params[:id])
    user.deactivate
    if user == current_user
      sign_out
      redirect_to after_sign_out_path_for(:user)
    else
      redirect_to admin_users_path
    end
  end

  def reactivate
    user = User.find(params[:id])
    user.reactivate
    redirect_to admin_users_path
  end

  private

  def search_params
    params.permit(:term)
  end
end
