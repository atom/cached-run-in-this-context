{
  "targets": [
    {
      "target_name": "cached-run-in-this-context",
      "sources": [ "src/cached-run-in-this-context.cc" ],
      "include_dirs" : [
        "<!(node -e \"require('nan')\")"
      ]
    }
  ]
}
