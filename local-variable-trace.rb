puts("Ruby: Insight version " + insight[:version] + " is launching")

#config = Truffle::Interop.hash_keys_as_members({
#  roots: true,
#  sourceFilter: -> (src) {
#    return src[:name].include? "capabilities.rb"
#  }
#})

insight.on("enter", -> (ctx, frame) {
    puts("camel_case for " + frame[:n].to_s)
})
