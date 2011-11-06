class ApplicationController < ActionController::Base
  protect_from_forgery
  
  def detect_mobile
    request.format = "mobile" if request.subdomains.first == "mobile"
  end
end
