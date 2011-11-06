class NewsController < ApplicationController
  def index
    @news_items = NewsItem.order("created_at desc").page(params[:page])
  end
end
