class Back::UsersController < BackController

  before_action :set_user, only: [:edit, :update]

  def edit

  end

  def update
    if user_params[:password].present?
      if user_params[:password] == user_params[:password_confirmation]
        @user.update_attributes(password: user_params[:password])
        flash[:success] = 'Your password has been updated successfully.'
      else
        flash[:error] = 'Your password was not updated: password confirmation did not match new password.'
      end
    else
      if @user.update_attributes(first_name: user_params[:first_name],
                                 last_name:  user_params[:last_name],
                                 email:      user_params[:email])
        flash[:success] = 'Your account has been updated successfully.'
      else
        flash[:error] = 'You account could not be updated.' # TODO this message is too vague and should give specific reason why the account was not update
      end
    end
    redirect_to edit_back_user_path(@user)
  end

  private

  def set_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation)
  end

end
