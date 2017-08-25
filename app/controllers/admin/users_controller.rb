module Admin
  class UsersController < BaseController
    before_action :verify_admin
    before_action :find_user, only: [:edit, :update]

    def index
      @users = User.all.page(params[:page])
    end

    def edit
    end

    def update
      params[:user].delete(:password) if params[:user][:password].blank?
      params[:user].delete(:password_confirmation) if params[:user][:password].blank? and params[:user][:password_confirmation].blank?
      if @user.update_attributes(user_params)
        flash[:notice] = "Successfully updated User."
        redirect_to admin_users_path
      else
        render :action => 'edit'
      end
    end

    private
    def verify_admin
      authorize :admin_panel, :users
    end

    def find_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit!
    end
  end
end
