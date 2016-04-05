module ApplicationHelper
# navbarのメニューアイテムの現在位置をアクティブにする
  def active_class(link_path)
    current_page?(link_path) ? "active" : ""
  end

  def get_foreign_hour(japanese_hour, hour_diff)
    if japanese_hour >= hour_diff
      foreign_hour = japanese_hour - hour_diff
    else
      foreign_hour = 24 + japanese_hour - hour_diff
    end
    return foreign_hour
  end
  # ロンドン時間の取得
  def get_London_hour(japanese_hour)
    hour_diff = 8
    return get_foreign_hour(japanese_hour.to_i, hour_diff)
  end

  def get_NewYork_hour(japanese_hour)
    hour_diff = 13
    return get_foreign_hour(japanese_hour.to_i, hour_diff)
  end
end
