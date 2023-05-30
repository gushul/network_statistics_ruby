# frozen_string_literal: true

require 'sinatra'
require 'json'

require_relative 'network_statistics'

before do
  content_type :json
end

post '/' do
  request_body = JSON.parse(request.body.read, symbolize_names: true)
  statistics = NetworkStatistics.collect(request_body)

  statistics.to_json
end
