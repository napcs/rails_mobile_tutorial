require 'test_helper'

class NewsItemTest < ActiveSupport::TestCase

  def test_requires_name
    n = NewsItem.new
    n.valid?
    assert n.errors[:name].include?("can't be blank")
  end

  def test_requires_body
    n = NewsItem.new
    n.valid?
    assert n.errors[:body].include?("can't be blank")
  end
end