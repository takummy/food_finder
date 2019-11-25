require 'dotenv'
require 'json'
require 'rest_client'
require 'sinatra'
require 'sinatra/reloader'
Dotenv.load

FB_ENDPOINT = ENV["TOKEN_URL"]
GNAVI_KEYID = ENV["GNAVI_KEYID"]
GNAVI_CATEGORY_LARGE_SEARCH_API = "https://api.gnavi.co.jp/master/CategoryLargeSearchAPI/v3/"

helpers do
  def get_categories
    response = JSON.parse(RestClient.get GNAVI_CATEGORY_LARGE_SEARCH_API + "?keyid=" + GNAVI_KEYID)
    categories = response["category_l"]
    categories
  end

  def filter_categories
    categories = []
    get_categories.each_with_index do |category, i|
      if i < 11
        hash = {
          content_type: 'text',
          title: category["category_l_name"],
          payload: category["category_l_code"],
        }
        p hash
        categories.push(hash)
      else
        p "11回目は配列に入れない"
      end
    end
    categories
  end

  def set_quick_reply_of_categories(sender, categories)
    {
      recipient: {
        id: sender
      },
      message: {
        text: "何が食べたいですか？",
        quick_replies: categories
      }
    }.to_json
  end

  def set_quick_reply_of_location(sender)
    {
      recipient: {
        id: sender
      },
      message: {
        text: "位置情報を送信してね！",
        quick_replies: [
          { content_type: "location" }
        ]
      }
    }.to_json
  end

  def get_location(message)
    lat = message["message"]["attachments"][0]["payload"]["coordinates"]["lat"]
    long = message["message"]["attachments"][0]["payload"]["coordinates"]["long"]
    [lat, long]
  end
end

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

  if message["message"]["text"] == "レストラン検索"

    categories = filter_categories
    request_body = set_quick_reply_of_categories(sender, categories)
    RestClient.post FB_ENDPOINT, request_body, content_type: :json, accept: :json
  elsif !message["message"]["quick_reply"]["payload"].nil?
    $requested_category_code = message["message"]["quick_reply"]["payload"]
    request_body = set_quick_reply_of_location(sender)
    RestClient.post FB_ENDPOINT, request_body, content_type: :json, accept: :json
  else
    text = "カテゴリーと位置情報からレストランを検索します。レストランを検索したい場合は、「レストラン検索」と話しかけてね！"
    content = {
      recipient: { id: sender },
      message: { text: text }
    }
    request_body = content.to_json

    RestClient.post FB_ENDPOINT, request_body, content_type: :json, accept: :json
  end
  status 201
  body ''
end