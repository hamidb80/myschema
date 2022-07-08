import sue/[parser, defs]
import print

when isMainModule:
  block commands:
    const texts = [
      "make_wire -1800 -950 -1880 -950 -origin {10 20}",
      "  make_wire -1800 -950 -1880 -950",
      "make io_pad_ami_c5n -name 'pad1' -origin {560 -1440}",
      "make io_pad_ami_c5n -orient R90Y -name pad14 -origin {-1680 -2480}",
      "make global -orient RXY -name vdd -origin {380 -510}",
      "make name_net -name {memdataout_s1[15]} -origin {-1860 -2100}",
      "make name_net -name {memdatain_v1[15]} -origin {-1790 -2220}",
      """
      make_text -origin {-1740 -2690} -text {This is the 
        schematic for AMI-C5N 0.5um technology}
      make_text -origin {-1740 -2660} -text Lambda=0.35um
      """
    ]

    for i, t in texts:
      echo "--- >> ", i+1
      # discard parseSue t

  block file:
    print parseSue readfile "./examples/eg1.sue"
