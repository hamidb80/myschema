import model
import ../common/[defs, seqs]

type Segment* = Slice[Point]

iterator toSegments*(head: NetGraphNode): Segment =
  var nstack: seq[tuple[node: NetGraphNode, connIndex: int]] = @[(head, 0)]

  while not isEmpty nstack:
    let (lastNode, i) = nstack.last

    if i == lastNode.connections.len:
      shoot nstack
    
    else:
      let nextNode = lastNode.connections[i]
      yield lastNode.location .. nextNode.location

      inc nstack.last.connIndex
      nstack.add (nextNode, 0)
