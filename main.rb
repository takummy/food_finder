require 'dotenv'
require 'jason'
require 'rest_client'
require 'sinatra'
require 'sinatra/reloader'
Dotenv.load

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
  hash = JASON.parse(request.body.read)
  messaging = hash["entry"][0]["messaging"][0]
  snder = messaging["sender"]["id"]
  text = messaging["message"]["text"]
  endpoint = ENV["TOKEN_URL"]
  content = {
    recipient: { id: sender },
    message: { text: text }
  }
  request_body = content.to_jason

  RestClient.post entrypoint, request_body, content_type: :jason, accept: :jason
  status 202
  body ''
end