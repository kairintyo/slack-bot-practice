require 'http'
require 'json'
require 'eventmachine'
require 'faye/websocket'

slackAPI = ''

response = HTTP.post("https://slack.com/api/rtm.start", params: {token: slackAPI })

rc = JSON.parse(response.body)

url = rc['url']

EM.run do
  ws = Faye::WebSocket::Client.new(url)
  users = {}

  ws.on :open do
    p [:open]
  end

  ws.on :message do |event|
    data = JSON.parse(event.data)
    p [:message, data]

    if !data['text'].nil?
      if data['text'].include?('感謝')
      user = data['text'].match(/[0-9A-Z]+/).to_s

        if users.has_key?(user.to_sym)
          users[user.to_sym] += 1
        else
          users[user.to_sym] = 1
        end

      ws.send({
        type: 'message',
        text: " <@#{user}> さんの現在の合計は#{users[user.to_sym]} です。",
        channel: data['channel']
      }.to_json)
      end
    end

    if !data['text'].nil?
      if data['text'] == ('合計数')
        users.each do | key, value|
          ws.send({
            type: 'message',
            text: "<@#{key}>:#{value}",
            channel: data['channel']
          }.to_json)
        end
      end
    end
  end

  ws.on :close do
    p [:close, event.code]
    ws = nil
    EM.stop
  end
end
