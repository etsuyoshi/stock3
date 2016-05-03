class StudyPagesController < ApplicationController
  def show
    # if routing -> get 'study_pages/*path', to: 'study_pages#show'
    @path = params[:path]
    p "path = #{@path}"
    # http://ja.stackoverflow.com/questions/11518/rails-4-2-階層を持った-url-の静的ページを1つのコントローラーでルーティングしたい#comment10439_11546
    render params[:path]

    # if routing -> get 'study_pages/*id', to: 'study_pages#show'
    # @id = params[:id]
    # p "id = #{@id}"
    # render params[:id]
  end
  def home
  end

  def help
  end
end
