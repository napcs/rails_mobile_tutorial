require 'test_helper'

class Admin::NewsItemsControllerTest < ActionController::TestCase

  def test_redirects_to_list_when_saved
    post :create, :news_item => {:name => "Test", :body => "test"}
    assert_redirected_to admin_news_items_url
  end

  def test_redisplays_form_when_save_fails
    post :create
    assert_template :new
  end
  
  def test_redirects_to_list_when_updated
    news_item = NewsItem.create :name => "Test", :body => "Test"
    put :update, :id => news_item.id, :news_item => {:name => "Test", :body => "test"}
    assert_redirected_to admin_news_items_url
  end
  
  def test_redisplays_form_when_update_fails
    news_item = NewsItem.create :name => "Test", :body => "Test"  
    put :update, :id => news_item.id, :news_item => {:name => "", :body => ""}
    assert_template :edit
  end
  
end
