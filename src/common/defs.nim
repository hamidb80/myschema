type
  Point* = tuple[x,y: int]
  
  Range*[T] = HSlice[T, T]
  
  Percent* = range[0.0 .. 1.0]