# frozen_string_literal: true

require 'rack/test'
require 'webmock/rspec'
require_relative '../main' # Replace with the actual filename of your code

RSpec.describe 'Server' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  before do
    WebMock.disable_net_connect!
  end

  describe 'POST /collect_statistics' do
    let(:request_body) do
      {
        endpoints: [
          {
            method: 'POST',
            url: 'http://example.com/info',
            headers: [
              {
                name: 'Cookie',
                value: 'token=DEADCAFE'
              }
            ],
            body: 'hello'
          }
        ],
        num_requests: 5,
        retry_failed: false
      }.to_json
    end

    it 'collects network statistics and returns the result' do
      stub_request(:post, 'http://example.com/info')
        .with(
          headers: {
            Accept: '*/*',
            "Accept-Encoding": 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            Cookie: 'token=DEADCAFE',
            "User-Agent": 'Ruby'
          }
        )
        .to_return(status: 200, body: '', headers: {})

      post '/', request_body

      expect(last_response).to be_ok
      expect(last_response.content_type).to eq('application/json')

      result = JSON.parse(last_response.body)
      expect(result['endpoints']).to be_an(Array)
      expect(result['summary']).to be_a(Hash)
    end
  end
end
