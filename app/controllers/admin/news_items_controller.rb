class Admin::NewsItemsController < ApplicationController
  def index
    @news_items = NewsItem.all
  end

  def new
    @news_item = NewsItem.new
  end

  def show
    @news_item = NewsItem.find(params[:id])
  end
  
  def edit
    @news_item = NewsItem.find(params[:id])
  end
  
  def create
    @news_item = NewsItem.new(params[:news_item])
    if @news_item.save
      redirect_to admin_news_items_url, :notice => "Created successfully."
    else
      render :action => "new"
    end
  end
  
  def update
    @news_item = NewsItem.find params[:id]
    if @news_item.update_attributes(params[:news_item])
      redirect_to admin_news_items_url, :notice => "Saved successfully."
    else
      render :action => "edit"
    end
  end

end
