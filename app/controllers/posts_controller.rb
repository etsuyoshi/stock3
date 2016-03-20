class PostsController < ApplicationController
  # logged_in_user is written in ApplicationController.rb
  before_action :logged_in_user, only:[:index, :create, :destroy]
  before_action :correct_user, only: :destroy

  def index
    # postsを取得し、
    @post = Post.paginate(page: params[:page])
  end
  def show
    @post = current_user.posts.build if logged_in?
  end

  def create
    @post = current_user.posts.build(post_params)
    if @post.save
      p "no error !"
      flash[:success] = "post created!"
      # redirect_to root_url：だめ
      redirect_to current_user
    else
      # p "error occurred!"
      # p "user_id = " + @post.user_id.to_s
      # p "title = " + @post.title.to_s
      # p "content = " + @post.content.to_s
      # p "error_message = " + @post.errors.full_messages.to_s
      # p "error count = " + @post.errors.count.to_s

      # このままだとエラー時に入力値保持されないので何かしら対応が必要！
      # http://qiita.com/seiya1121/items/cf6b44fae757f6300ada
      @post.errors.full_messages.each do |error|
        flash[:danger] = error
      end

      @feed_items = []
      redirect_to current_user
    end
  end

  def destroy
    @post.destroy
    flash[:success] = "Post deleted!"
    redirect_to request.referrer || root_url
  end

  private
    def post_params
      params.require(:post).permit(:title, :content, :picture)
    end

    def correct_user
      @post = current_user.posts.find_by(id: params[:id])
      redirect_to root_url if @post.nil?
    end
end
