puts("Ruby: Insight version " + insight[:version] + " is launching")

config = Truffle::Interop.hash_keys_as_members({
  roots: true,
  rootNameFilter: "camel_case"
})

insight.on("enter", -> (ctx, frame) {
    puts("camel_case for " + frame[:n].to_s)
}, config)
