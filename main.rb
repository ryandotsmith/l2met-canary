$stdout.sync = true

require 'atomic'
require 'time'
require 'thread'
require 'net/http'
require 'uri'

Thread.abort_on_exception = true

Thread.new do
  loop do
    beats.each do |source, val|
      n = val.swap(0)
      puts fmt(at: source, received: n)
    end
    sleep(60)
  end
end

def pulse(source)
  beats[source] ||= Atomic.new(0)
  beats[source].update {|n| n + 1}
end

def beats
  @beats ||= {}
end

def fmt(data)
  data.reduce(out=String.new) do |s, tup|
    s << [tup.first, tup.last].join("=") << " "
  end
  out
end

def base
  "<13>1 #{Time.now.iso8601} app main.1 d.3dfe0f7c-a554-4e15-bf98-2eefc9e0192e - "
end

def post(data)
  line = base + fmt(data)
  line = [line.length.to_s, line].join(" ")
  uri = URI.parse(ENV["DRAIN_URL"])
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  request = Net::HTTP::Post.new(uri.request_uri)
  request.body = line
  http.request(request)
  pulse(["http", (data[:at] || data[:fn])].join("."))
end

loop do
  sleep(1)
  t = Time.now.to_i
  (ENV["LINES"] || 1).to_i.times do |i|
    d = {app: "l2met-canary", measure: true}
    Thread.new do
      puts fmt(d.merge(at: "canary-drain-count"))
      post(d.merge(fn: "canary-post-list", elapsed: 3.14))
      post(d.merge(at: "canary-post-last", last: Time.now.to_i - 60))
    end
  end
end
