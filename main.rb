require 'dotenv'
require 'json'
require 'rest_client'
require 'sinatra'
require 'sinatra/reloader'
Dotenv.load

FB_ENDPOINT = ENV["TOKEN_URL"]

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
  hash = JSON.parse(request.body.read)
  message = hash["entry"][0]["messaging"][0]
  sender = message["sender"]["id"]
  text = "カテゴリーと位置情報からレストランを検索します。レストランを検索したい場合は、「レストラン検索」と話しかけてね！"
  content = {
    recipient: { id: sender },
    message: { text: text }
  }
  request_body = content.to_json

  RestClient.post FB_ENDPOINT, request_body, content_type: :json, accept: :json
  status 201
  body ''
end