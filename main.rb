require 'jason'
require 'sinatra'
require 'sinatra/reloader'

get '/' do
  "Hello, world!"
end

get '/callback' do
  if params["hub.verify_token"] != 'hogehoge'
    return 'Error, wrong validation token.'
  end

  params["hub.challenge"]
end

post '/callback' do
  request_body = JASON.parse(request.body.read)
  puts request_body
  status 201
  body ''
end