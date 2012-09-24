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
      log(at: source, received: n)
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


def log(data)
  data = {app: "l2met-canary"}.merge(data)
  data.reduce(out=String.new) do |s, tup|
    s << [tup.first, tup.last].join("=") << " "
  end
  puts(out)
end

def post(data)
  line = "146 <13>1 #{Time.at(data[:time]).iso8601} app main.1 d.3dfe0f7c-a554-4e15-bf98-2eefc9e0192e - app=l2met-canary measure=true at=canary-http time=#{data[:time]}"
  uri = URI.parse(ENV["DRAIN_URL"])
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  request = Net::HTTP::Post.new(uri.request_uri)
  request.body = line
  response = http.request(request)
  pulse("http")
end

loop do
  sleep(1)
  t = Time.now.to_i
  (ENV["LINES"] || 1).to_i.times do |i|
    d = {measure: true, at: "canary-test", time: t + i}
    Thread.new {log(d); post(d)}
  end
end
