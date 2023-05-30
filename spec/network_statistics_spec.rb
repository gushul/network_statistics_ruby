# frozen_string_literal: true

require 'rspec'
require 'webmock/rspec'
require_relative '../network_statistics'

RSpec.describe NetworkStatistics do
  before do
    WebMock.disable_net_connect!
  end

  describe '#send_request' do
    context 'when all is ok' do
      let(:endpoint) do
        {
          method: 'GET',
          url: 'http://example.com',
          headers: [],
          body: nil
        }
      end

      it 'returns the response and duration for a successful request' do
        stub_request(:get, 'http://example.com')
          .to_return(status: 200, body: 'Response body')

        result = described_class.send_request(endpoint)

        expect(result[:response].class).to eq(Net::HTTPOK)
        expect(result[:duration]).to be > 0
      end
    end

    context 'when the request fails' do
      let(:endpoint) do
        {
          url: 'http://example.com',
          headers: [],
          body: nil
        }
      end

      it 'returns -1 duration for a timed out request' do
        stub_request(:get, 'http://example.com')
          .to_timeout

        result = described_class.send_request(endpoint)

        expect(result[:response]).to be_nil
        expect(result[:duration]).to eq(-1)
      end
    end
  end

  describe '#collect' do
    let(:failed_expectation) do
      {
        min: -1,
        max: -1,
        avg: -1,
        fails: 5
      }
    end

    context 'when send request to endpoint and all is ok' do
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
        }
      end

      it 'collects network statistics for a valid request' do
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

        statistics = described_class.collect(request_body)

        expect(statistics[:endpoints].first[:min]).to be_a_kind_of(Float)
        expect(statistics[:endpoints].first[:max]).to be_a_kind_of(Float)
        expect(statistics[:endpoints].first[:avg]).to be_a_kind_of(Float)
        expect(statistics[:endpoints].first[:fails]).to eq(0)

        expect(statistics[:summary][:min]).to be_a_kind_of(Float)
        expect(statistics[:summary][:max]).to be_a_kind_of(Float)
        expect(statistics[:summary][:avg]).to be_a_kind_of(Float)
        expect(statistics[:summary][:fails]).to eq(0)
      end
    end

    context 'when send request to endpoint and request failed' do
      let(:request_body) do
        {
          endpoints: [
            {
              method: 'GET',
              url: 'http://example.com/info',
              headers: [],
              body: nil
            }
          ],
          num_requests: 5,
          retry_failed: true
        }
      end

      it 'handles failed requests and retries' do
        stub_request(:get, 'http://example.com/info')
          .to_return(status: 500)
          .times(5)

        statistics = described_class.collect(request_body)

        expect(statistics[:endpoints].first[:fails]).to eq(5)

        expect(statistics[:endpoints]).to eq([failed_expectation])
        expect(statistics[:summary]).to eq(failed_expectation)
      end
    end

    context 'when send requests to two endpoints and request failed' do
      let(:request_body) do
        {
          endpoints: [
            {
              method: 'GET',
              url: 'http://example.com/info',
              headers: [],
              body: nil
            },
            {
              method: 'POST',
              url: 'http://example.com/sum',
              headers: [],
              body: nil
            }

          ],
          num_requests: 5,
          retry_failed: true
        }
      end

      it 'handles 2 failed requests and retries' do
        stub_request(:get, 'http://example.com/info')
          .to_return(status: 500)
          .times(5)

        stub_request(:post, 'http://example.com/sum')
          .to_return(status: 500)
          .times(5)

        statistics = described_class.collect(request_body)

        expect(statistics[:endpoints].first[:fails]).to eq(5)

        expect(statistics[:endpoints]).to eq([failed_expectation, failed_expectation])
        expect(statistics[:summary]).to eq({ min: -1, max: -1, avg: -1, fails: 10 })
      end
    end

    context 'when send requests to two endpoints and one request failed' do
      let(:request_body) do
        {
          endpoints: [
            {
              method: 'GET',
              url: 'http://example.com/info',
              headers: [],
              body: nil
            },
            {
              method: 'POST',
              url: 'http://example.com/sum',
              headers: [],
              body: nil
            }

          ],
          num_requests: 5,
          retry_failed: true
        }
      end

      it 'handles 1 failed and 1 sucessfull requests' do
        request_body = {
          endpoints: [
            {
              method: 'GET',
              url: 'http://example.com/info',
              headers: [],
              body: nil
            },
            {
              method: 'POST',
              url: 'http://example.com/sum',
              headers: [],
              body: nil
            }

          ],
          num_requests: 5,
          retry_failed: true
        }

        stub_request(:get, 'http://example.com/info')
          .to_return(status: 500)
          .times(5)

        stub_request(:post, 'http://example.com/sum')
          .to_return(status: 200)

        statistics = described_class.collect(request_body)

        expect(statistics[:endpoints].first[:fails]).to eq(5)

        expect(statistics[:endpoints].first).to eq(failed_expectation)
      end
    end
  end
end
