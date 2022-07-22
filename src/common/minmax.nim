type MinMax*[T] = object
  isInitialized: bool
  slice: Slice[T]

func update*[T](mm: var MinMax[T], val: T) = 
  if mm.isInitialized:
    if val > mm.max:
      mm.slice.b = val
    elif val < mm.min:
      mm.slice.a = val
  
  else:
    mm.slice = val .. val

func max*[T](mm: MinMax[T]): T =
  doAssert mm.isInitialized
  mm.slice.b

func min*[T](mm: MinMax[T]): T =
  doAssert mm.isInitialized
  mm.slice.a

func len*[T](mm: MinMax[T]): T =
  mm.max - mm.min