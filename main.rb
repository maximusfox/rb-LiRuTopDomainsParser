#!/usr/bin/env ruby
# Парсим рейтинг li.ru

require 'socksify'
require 'concurrent'
require 'httparty'
require 'tsv'
require 'pp'

# Proxy debuging
# Socksify.debug = false

# Proxy
TCPSocket.socks_server = '127.0.0.1'
TCPSocket.socks_port = 9050

# Concurrent requests count
CONCURRENT_REQUESTS_BATCH_SIZE = 1000

class LiveInternetTopApi
  include Concurrent::Async

  include TSV
  include HTTParty

  base_uri 'www.liveinternet.ru'
  headers 'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36'

  def initialize; end

  def pages_count
    per_page = 30

    data = self.class.get('/rating/today.tsv?page=1').to_s
    tsv_lines = data.split("\n")
    header = tsv_lines[0]

    header_rows = header.split("\t")
    total_rows = Integer(header_rows[1])

    # Original JS: Math.floor((totalRows - 1) / perPage) + 1;
    ((total_rows - 1) / per_page).floor
  end

  def tsv(page)
    options = { query: { page: page } }
    data = self.class.get('/rating/today.tsv', options).to_s

    data.sub!(/^.+?\n/, '')
    data.sub!(/\r?\n\r?\n$/, '')

    { response: TSV.parse(data), id: page }
  end

  # TODO: Понять какого хрена оно крашится
  # def csv(page)
  #   options = { query: { page: page } }
  #   self.class.get('/rating/today.csv', options)
  # end
end

live_internet_top_api = LiveInternetTopApi.new
pages_id_list = *(1...live_internet_top_api.pages_count + 1)

loop do
  break if pages_id_list.empty?

  batch = []
  CONCURRENT_REQUESTS_BATCH_SIZE.times do
    break if pages_id_list.empty?

    batch << pages_id_list.shift
  end

  responses = batch.map { |id| LiveInternetTopApi.new.async.tsv(id) }
  responses.each do |item|
    results = []
    value = item.value

    value[:response].without_header.map do |row|
      row[1].sub!(%r{/.*$}, '')
      row[1].sub!(/^www\./, '')
      results << row[1]
    end
    puts "Page: #{value[:id]} Results: #{results.count}"

    File.open('domains.txt', 'a') { |f| f.write(results.join("\n") + "\n") }
  end
end
