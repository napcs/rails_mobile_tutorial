class NewsController < ApplicationController
  def index
    @news_items = NewsItem.order("created_at desc").page(params[:page])

    respond_to do |format|
      format.html #do nothing.
      format.json { render :json => @news_items.to_json }
      format.xml { render :xml => @news_items.to_xml }
    end

  end
end
