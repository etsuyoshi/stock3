crumb :root do
  link "Home", root_path
end

# Issue list
crumb :study do
  link "株式講座"
  parent :root
end

# 初級編
crumb :study_aboutstock do
  link "株とは"
  parent :study
end

crumb :study_stockmechanism do
  link "株の仕組み"
  parent :study
end

# 中級編
crumb :study_securities_fee do
  link "手数料"
  parent :study
end

crumb :study_securities_matsui do
  link "松井証券で口座を開く"
  parent :study
end

crumb :news do
  link "ニュース"
  parent :root
end


crumb :nikkei do
  link "日経平均"
  parent :root
end

crumb :fx do
  link "為替"
  parent :root
end

crumb :dow do
  link "ダウ平均"
  parent :root
end

crumb :shanghai do
  link "上海総合"
  parent :root
end
crumb :europe do
  link "欧州"
  parent :root
end
crumb :bitcoin do
  link "ビットコイン"
  parent :root
end
crumb :commodity do
  link "商品価格"
  parent :root
end
crumb :adr do
  link "日本株ADR"
  parent :root
end

crumb :kessan do
  link "決算"
  parent :root
end

crumb :login do
  link "ログイン"
  parent :root
end

# crumb :projects do
#   link "Projects", projects_path
# end

# crumb :project do |project|
#   link project.name, project_path(project)
#   parent :projects
# end

# crumb :project_issues do |project|
#   link "Issues", project_issues_path(project)
#   parent :project, project
# end

# crumb :issue do |issue|
#   link issue.title, issue_path(issue)
#   parent :project_issues, issue.project
# end

# If you want to split your breadcrumbs configuration over multiple files, you
# can create a folder named `config/breadcrumbs` and put your configuration
# files there. All *.rb files (e.g. `frontend.rb` or `products.rb`) in that
# folder are loaded and reloaded automatically when you change them, just like
# this file (`config/breadcrumbs.rb`).
