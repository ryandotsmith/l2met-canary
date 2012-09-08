$stdout.sync = true

def log(data)
  data = {app: "l2met-canary"}.merge(data)
  data.reduce(out=String.new) do |s, tup|
    s << [tup.first, tup.last].join("=") << " "
  end
  puts(out)
end

loop do
  sleep(1)
  (ENV["LINES"] || 1).to_i.times do
    log(measure: true, at: "canary-test")
  end
end
