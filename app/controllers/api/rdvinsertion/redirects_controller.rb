class Api::Rdvinsertion::RedirectsController < ApplicationController
  def create
    target = if ENV["HOST"].include?("demo")
               "https://rdv-insertion-demo.fr"
             elsif ENV["HOST"].include?("localhost")
               "http://localhost:8000"
             else
               "https://rdv-insertion.fr"
             end

    redirect_to [target, request.fullpath.sub("/rdvi", "")].join, allow_other_host: true
  end
end
