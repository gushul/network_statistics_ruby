# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'timeout'

class NetworkStatistics
  DB_NAME = 'statistics.db'
  DEFAULT_NUM_REQUESTS = 10
  DEFAULT_RETRY_FAILED = false
  DEFAULT_METHOD = 'Get'
  FAILED_DURATION = -1
  MAX_CORRECT_RESPONSE_CODE = 299

  def self.send_request(endpoint)
    uri = URI.parse(endpoint[:url])
    http = Net::HTTP.new(uri.host, uri.port)
    if uri.instance_of? URI::HTTPS
      http.use_ssl = true if uri.instance_of? URI::HTTPS
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    method = endpoint[:method]&.capitalize || DEFAULT_METHOD
    request = Net::HTTP.const_get(method).new(uri.request_uri)
    endpoint[:headers].each { |header| request[header[:name]] = header[:value] }
    request.body = endpoint[:body] if endpoint['body']

    response = nil
    duration = nil
    begin
      Timeout.timeout(10) do # Timeout set to 10 seconds
        start_time = Time.now
        response = http.request(request)

        duration = if response.code.to_i > MAX_CORRECT_RESPONSE_CODE
                     -1 # Set duration to -1 if request failed
                   else
                     (Time.now - start_time) * 1000 # Convert to milliseconds
                   end
      end
    rescue Timeout::Error
      duration = -1 # Set duration to -1 for timed out requests
    end

    { response:, duration: }
  end

  def self.collect(request_body)
    endpoints = request_body[:endpoints]
    num_requests = request_body[:num_requests] || DEFAULT_NUM_REQUESTS
    retry_failed = request_body[:retry_failed] || DEFAULT_RETRY_FAILED

    endpoint_stats = []

    endpoints.each do |endpoint|
      min_duration = FAILED_DURATION
      max_duration = FAILED_DURATION
      total_duration = 0
      fails = 0

      num_requests.times do
        result = send_request(endpoint)

        if result[:duration] != FAILED_DURATION
          min_duration = result[:duration] if min_duration == FAILED_DURATION || result[:duration] < min_duration
          max_duration = result[:duration] if result[:duration] > max_duration
          total_duration += result[:duration]
        else
          fails += 1
          break unless retry_failed
        end
      end

      avg_duration = total_duration != 0 ? total_duration / (num_requests - fails) : -1

      endpoint_stats << {
        min: min_duration,
        max: max_duration,
        avg: avg_duration,
        fails:
      }
    end

    summary = {}

    if endpoint_stats.any?
      summary[:min] = endpoint_stats.map { |e| e[:min] }.reject { |d| d == -1 }.min || -1
      summary[:max] = endpoint_stats.map { |e| e[:max] }.max || -1
      summary[:avg] = fetch_summary_avg(endpoint_stats.map { |e| e[:avg] }, endpoint_stats.length)

      summary[:fails] = endpoint_stats.map { |e| e[:fails] }.sum
    end

    {
      endpoints: endpoint_stats,
      summary: summary
    }
  end

  def self.fetch_summary_avg(avgs, enpoints_count)
    return -1 if avgs.empty?
    return -1 if avgs.uniq.last == -1

    avgs.reject { |d| d == -1 }.sum / enpoints_count
  end
end
