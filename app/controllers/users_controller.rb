class UsersController < ApplicationController
  # before_action :logged_in_user, only: [:index, :edit, :update, :destroy]
  before_action :correct_user,   only: [:edit, :update]
  before_action :admin_user,     only: :destroy

  def index
    @users = User.paginate(page: params[:page])
  end
  def new
    @user = User.new
  end

  # リスト11.38: homeアクションにマイクロポストのインスタンス変数を追加する
  def show

    @user = User.find(params[:id])
    # 自分のポスト
    @posts = @user.posts.paginate(page: params[:page])
    # フィード＝他人のポストも合わせたもの
    @feed_items = @user.feed.paginate(page: params[:page])
    @post = current_user.posts.build if logged_in?
    # @post = Post.new
    

  end

  def create
    @user = User.new(user_params)
    if @user.save
      log_in @user
      flash[:success] = "Welcome to member page!"
      # handle a successful save
      redirect_to @user#equal to below code
      # redirect_to user_url(@user)

    else
      render 'new'
    end
  end
  def destroy
    User.find(params[:id]).destroy
    flash[:success] = "User deleted"
    redirect_to users_url
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update_attributes(user_params)
      # 更新に成功した時
      flash[:success] = "Profile updated"
      redirect_to @user
    else
      render 'edit'
    end
  end

  private
    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end
    # application_controllerに移譲(PostsControllerでも必要なため)
    # def logged_in_user
    #   unless logged_in?
    #     store_location
    #     flash[:danger] = "Please log in."
    #     redirect_to login_url
    #   end
    # end
    # 正しいユーザーかどうか確認
    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_url) unless current_user?(@user)
    end

    # 管理者かどうか確認
    def admin_user
      redirect_to(root_url) unless current_user.admin?
    end
end