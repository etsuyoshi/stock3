module ApplicationHelper
# navbarのメニューアイテムの現在位置をアクティブにする
  def active_class(link_path)
    current_page?(link_path) ? "active" : ""
   end

   
end
