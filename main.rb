$stdout.sync = true

require 'time'
require 'thread'
require 'net/http'
require 'uri'

DELAY = (ENV["DELAY"] || 0).to_i

def base
  "<13>1 #{(Time.now - DELAY).iso8601} app main.1 fake.logplex.token - - "
end

def post(url, msg)
  line = base + msg
  line = [line.length.to_s, line].join(" ")
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  request = Net::HTTP::Post.new(uri.request_uri)
  request.body = line
  http.request(request)
  $stdout.puts("http-post")
end

loop do
  sleep(1)
  (ENV["LINES"] || 1).to_i.times do
    post(ENV["L2MET_URL"], 'measure="l2met-canary.http-post" val=3.14')
    $stdout.puts('measure="l2met-canary.drain"')
  end
end
