type MinMax*[T] = object
  isInitialized: bool
  low, high: T

func update*[T](mm: var MinMax[T], val: T) = 
  if mm.isInitialized:
    if val > mm.high:
      mm.high = val
    elif val < mm.low:
      mm.low = val
  
  else:
    mm.low = val
    mm.high = val
    mm.isInitialized = true

func max*[T](mm: MinMax[T]): T =
  doAssert mm.isInitialized
  mm.high

func min*[T](mm: MinMax[T]): T =
  doAssert mm.isInitialized
  mm.low

func len*[T](mm: MinMax[T]): T =
  mm.max - mm.min

func toSlice*[T](mm: MinMax[T]): Slice[T] = 
  mm.low .. mm.high