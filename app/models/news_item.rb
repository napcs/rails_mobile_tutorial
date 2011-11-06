class NewsItem < ActiveRecord::Base
  validates_presence_of :name, :body 
  
end
