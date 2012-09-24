# l2met-canary

[l2met](http://github.com/ryandotsmith/l2met) is a service that receives log messages over HTTPs and converts them into metrics. **l2met-canary** will test l2met by providing a baseline servie. This canary will send 1 * ENV["LINES"] messages to a log drain and to a direct HTTP connection to l2met.
