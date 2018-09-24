import ../finals

type MyObject = object of RootObj
    a: int

finals:
    type RefObject = ref MyObject
