# MUST be run with -d:release to show bug

import ../finals

finalsd:
    type Test = ref object of RootObj
      field* {.final.}: string

var a: Test = Test()
a.field = "a"
a.ffinalizeField()
