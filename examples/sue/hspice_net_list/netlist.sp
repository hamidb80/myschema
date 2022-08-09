set NETLIST_CACHE(Master_Pld_Bus2,cells) {
	{schematic Master_single_read}
	{schematic Master_alu}
	{schematic buffer0}
}

set netlist_props spice
set netlist_level 1000
set NETLIST_CACHE(Master_Pld_Bus2,level) main
set NETLIST_CACHE(Master_Pld_Bus2,version) MMI_SUE4.4.0

set NETLIST_CACHE(Master_Pld_Bus2) {
    {* start main CELL Master_Pld_Bus2}
    {* .SUBCKT 
      Master_Pld_Bus2 
      HADDR_master1[0:31] 
      HADDR_master2[0:31] HBURST_master1[0] HBURST_master1[1]
      HBURST_master1[2] HBURST_master2[0] HBURST_master2[1] HBURST_master2[2]
      HBUSREQ_pld_bus2[0] HBUSREQ_pld_bus2[1] HBUSREQ_pld_bus2[2]
      HBUSREQ_stripe HCLK HGRANT_pld_bus2[0] HGRANT_pld_bus2[1]
      HGRANT_pld_bus2[2] HRDATA_pld_bus2[0] HRDATA_pld_bus2[1]
      HRDATA_pld_bus2[2] HRDATA_pld_bus2[3] HRDATA_pld_bus2[4]
      HRDATA_pld_bus2[5] HRDATA_pld_bus2[6] HRDATA_pld_bus2[7]
      HRDATA_pld_bus2[8] HRDATA_pld_bus2[9] HRDATA_pld_bus2[10]
      HRDATA_pld_bus2[11] HRDATA_pld_bus2[12] HRDATA_pld_bus2[13]
      HRDATA_pld_bus2[14] HRDATA_pld_bus2[15] HRDATA_pld_bus2[16]
      HRDATA_pld_bus2[17] HRDATA_pld_bus2[18] HRDATA_pld_bus2[19]
      HRDATA_pld_bus2[20] HRDATA_pld_bus2[21] HRDATA_pld_bus2[22]
      HRDATA_pld_bus2[23] HRDATA_pld_bus2[24] HRDATA_pld_bus2[25]
      HRDATA_pld_bus2[26] HRDATA_pld_bus2[27] HRDATA_pld_bus2[28]
      HRDATA_pld_bus2[29] HRDATA_pld_bus2[30] HRDATA_pld_bus2[31]
      HREADY_OUT_pld_bus2 HRESETn HRESP_pld_bus2[0] HRESP_pld_bus2[1]
      HSIZE_master1[0] HSIZE_master1[1] HSIZE_master1[2] HSIZE_master2[0]
      HSIZE_master2[1] HSIZE_master2[2] HTRANS_master1[0] HTRANS_master1[1]
      HTRANS_master2[0] HTRANS_master2[1] HWDATA_master1[0] HWDATA_master1[1]
      HWDATA_master1[2] HWDATA_master1[3] HWDATA_master1[4] HWDATA_master1[5]
      HWDATA_master1[6] HWDATA_master1[7] HWDATA_master1[8] HWDATA_master1[9]
      HWDATA_master1[10] HWDATA_master1[11] HWDATA_master1[12]
      HWDATA_master1[13] HWDATA_master1[14] HWDATA_master1[15]
      HWDATA_master1[16] HWDATA_master1[17] HWDATA_master1[18]
      HWDATA_master1[19] HWDATA_master1[20] HWDATA_master1[21]
      HWDATA_master1[22] HWDATA_master1[23] HWDATA_master1[24]
      HWDATA_master1[25] HWDATA_master1[26] HWDATA_master1[27]
      HWDATA_master1[28] HWDATA_master1[29] HWDATA_master1[30]
      HWDATA_master1[31] HWDATA_master2[0] HWDATA_master2[1] HWDATA_master2[2]
      HWDATA_master2[3] HWDATA_master2[4] HWDATA_master2[5] HWDATA_master2[6]
      HWDATA_master2[7] HWDATA_master2[8] HWDATA_master2[9] HWDATA_master2[10]
      HWDATA_master2[11] HWDATA_master2[12] HWDATA_master2[13]
      HWDATA_master2[14] HWDATA_master2[15] HWDATA_master2[16]
      HWDATA_master2[17] HWDATA_master2[18] HWDATA_master2[19]
      HWDATA_master2[20] HWDATA_master2[21] HWDATA_master2[22]
      HWDATA_master2[23] HWDATA_master2[24] HWDATA_master2[25]
      HWDATA_master2[26] HWDATA_master2[27] HWDATA_master2[28]
      HWDATA_master2[29] HWDATA_master2[30] HWDATA_master2[31] HWRITE_master1
      HWRITE_master2 master1_bus_error master1_haddress[0] master1_haddress[1]
      master1_haddress[2] master1_haddress[3] master1_haddress[4]
      master1_haddress[5] master1_haddress[6] master1_haddress[7]
      master1_haddress[8] master1_haddress[9] master1_haddress[10]
      master1_haddress[11] master1_haddress[12] master1_haddress[13]
      master1_haddress[14] master1_haddress[15] master1_haddress[16]
      master1_haddress[17] master1_haddress[18] master1_haddress[19]
      master1_haddress[20] master1_haddress[21] master1_haddress[22]
      master1_haddress[23] master1_haddress[24] master1_haddress[25]
      master1_haddress[26] master1_haddress[27] master1_haddress[28]
      master1_haddress[29] master1_haddress[30] master1_haddress[31]
      master1_hrdata[0] master1_hrdata[1] master1_hrdata[2] master1_hrdata[3]
      master1_hrdata[4] master1_hrdata[5] master1_hrdata[6] master1_hrdata[7]
      master1_hrdata[8] master1_hrdata[9] master1_hrdata[10]
      master1_hrdata[11] master1_hrdata[12] master1_hrdata[13]
      master1_hrdata[14] master1_hrdata[15] master1_hrdata[16]
      master1_hrdata[17] master1_hrdata[18] master1_hrdata[19]
      master1_hrdata[20] master1_hrdata[21] master1_hrdata[22]
      master1_hrdata[23] master1_hrdata[24] master1_hrdata[25]
      master1_hrdata[26] master1_hrdata[27] master1_hrdata[28]
      master1_hrdata[29] master1_hrdata[30] master1_hrdata[31]
      master1_start_trans master2_start_trans
    }
    {
      Xhepler_lEQ7qTj2HW HBUSREQ_stripe HBUSREQ_pld_bus2[0] buffer0
    }
    {
      XMaster1 
        HADDR_master1[0:31]
        HBURST_master1[0:2]
        HBUSREQ_pld_bus2[1] 
        HCLK 
        HGRANT_pld_bus2[1] 
        HRDATA_pld_bus2[0:31] 
        HREADY_OUT_pld_bus2 
        HRESETn 
        HRESP_pld_bus2[0:1] 
        HSIZE_master1[0:2]
        HTRANS_master1[0:1] 
        HWDATA_master1[0:31] 
        HWRITE_master1 
        master1_bus_error 
        master1_haddress[0:31] 
        master1_hrdata[0:31] 
        master1_start_trans
      Master_single_read 
    }
    {
      XMaster2 
        HADDR_master2[0:31] 
        HBURST_master2[0:2]
        HBUSREQ_pld_bus2[2] HCLK HGRANT_pld_bus2[2] HREADY_OUT_pld_bus2 HRESETn
        HRESP_pld_bus2[0:1] 
        HSIZE_master2[0:2] HTRANS_master2[0:1] 
        HWDATA_master2[0:31] 
        HWRITE_master2 
        master2_start_trans
      Master_alu 
    }

    {* .ENDS	$ Master_Pld_Bus2} {}
}

set NETLIST_CACHE(Master_Pld_Bus2,names) {
    {4672 3648 {0 HBURST_master2[2:0]}}
    {4672 2048 {0 HSIZE_master1[2:0]}}
    {1280 448 {1 HRESETn} {3 HRESETn}}
    {6272 1920 {1 HWDATA_master1[31:0]}}
    {4672 1792 {0 HBURST_master1[2:0]}}
    {4672 1408 {0 HTRANS_master1[1:0]}}
    {2432 3648 {1 HRESETn} {2 HRESETn}}
    {6272 3776 {1 HWDATA_master2[31:0]}}
    {6272 2176 {1 master1_hrdata[31:0]}}
    {2432 2048 {0 HRDATA_pld_bus2[31:0]}}
    {4672 3264 {0 HTRANS_master2[1:0]}}
    {5440 3136 {1 HBUSREQ_pld_bus2[2]}}
    {4672 3904 {0 HSIZE_master2[2:0]}}
    {1080 576  {1 HBUSREQ_stripe}}
    {4672 2304 {0 master1_bus_error}}
    {2432 1792 {1 HRESETn} {2 HRESETn}}
    {5440 576  {1 HBUSREQ_pld_bus2[0]}}
    {1280 1344 {1 HGRANT_pld_bus2[2:0]}}
    {5440 1280 {1 HBUSREQ_pld_bus2[1]}}
    {6272 1536 {1 HADDR_master1[31:0]}}
    {2432 1408 {0 HGRANT_pld_bus2[1]}}
    {2432 3264 {0 HGRANT_pld_bus2[2]}}
    {6272 3392 {1 HADDR_master2[31:0]}}
    {2432 1088 {0 XMaster1}}
    {1280 1664 {1 HRESP_pld_bus2[1:0]}}
    {4672 3520 {0 HWRITE_master2}}
    {1280 320  {1 HCLK} {3 HCLK}}
    {1280 3136 {1 master2_start_trans}}
    {1260 576  {0 Xhepler_lEQ7qTj2HW} {1 HBUSREQ_stripe}}
    {4672 1664 {0 HWRITE_master1}}
    {2432 3520 {0 HRESP_pld_bus2[1:0]}}
    {1280 1280 {1 master1_start_trans}}
    {6272 3648 {1 HBURST_master2[2:0]}}
    {6272 2048 {1 HSIZE_master1[2:0]}}
    {4672 3136 {0 HBUSREQ_pld_bus2[2]}}
    {1280 2176 {1 master1_haddress[31:0]}}
    {6272 1792 {1 HBURST_master1[2:0]}}
    {2432 1664 {0 HRESP_pld_bus2[1:0]}}
    {4672 1280 {0 HBUSREQ_pld_bus2[1]}}
    {5504 512  {1 HBUSREQ_pld_bus2[2:0]}}
    {6272 1408 {1 HTRANS_master1[1:0]}}
    {4672 1920 {0 HWDATA_master1[31:0]}}
    {2432 3136 {0 master2_start_trans}}
    {6272 3264 {1 HTRANS_master2[1:0]}}
    {6272 3904 {1 HSIZE_master2[2:0]}}
    {4672 3776 {0 HWDATA_master2[31:0]}}
    {1280 1536 {1 HREADY_OUT_pld_bus2}}
    {6272 2304 {1 master1_bus_error}}
    {4672 2176 {0 master1_hrdata[31:0]}}
    {1280 576  {0 HBUSREQ_pld_bus2[0]}}
    {2432 1280 {0 master1_start_trans}}
    {2432 1920 {1 HCLK} {2 HCLK}}
    {5504 1216 {1 HBUSREQ_pld_bus2[2:0]}}
    {1920 3200 {1 HGRANT_pld_bus2[2:0]}}
    {4672 1536 {0 HADDR_master1[31:0]}}
    {5504 3072 {1 HBUSREQ_pld_bus2[2:0]}}
    {2432 3776 {1 HCLK} {2 HCLK}}
    {1984 1408 {1 HGRANT_pld_bus2[1]}}
    {6272 3520 {1 HWRITE_master2}}
    {2432 2176 {0 master1_haddress[31:0]}}
    {4672 3392 {0 HADDR_master2[31:0]}}
    {1984 3264 {1 HGRANT_pld_bus2[2]}}
    {1920 1344 {1 HGRANT_pld_bus2[2:0]}}
    {1280 2048 {1 HRDATA_pld_bus2[31:0]}}
    {6272 448  {1 HBUSREQ_pld_bus2[2:0]}}
    {6272 1664 {1 HWRITE_master1}}
    {2432 1536 {0 HREADY_OUT_pld_bus2}}
    {2432 3392 {0 HREADY_OUT_pld_bus2}}
    {2432 3008 {0 XMaster2}}
}

set NETLIST_CACHE(Master_Pld_Bus2,wires) {
    {5440 3136 5504 3072 HBUSREQ_pld_bus2[2:0]}
    {1080 576 1260 576 HBUSREQ_stripe}
    {5440 1280 5504 1216 HBUSREQ_pld_bus2[2:0]}
    {5440 576 5504 512 HBUSREQ_pld_bus2[2:0]}
    {1920 1344 1984 1408 HGRANT_pld_bus2[2:0]}
    {1920 3200 1984 3264 HGRANT_pld_bus2[2:0]}
    {5504 1216 5504 3072 HBUSREQ_pld_bus2[2:0]}
    {5504 512 5504 1216 HBUSREQ_pld_bus2[2:0]}
    {5504 448 5504 512 HBUSREQ_pld_bus2[2:0]}
    {5504 448 6208 448 HBUSREQ_pld_bus2[2:0]}
    {6208 448 6272 448 HBUSREQ_pld_bus2[2:0]}
    {1344 1280 2368 1280 master1_start_trans}
    {1280 1280 1344 1280 master1_start_trans}
    {2368 1280 2432 1280 master1_start_trans}
    {2368 3392 2432 3392 HREADY_OUT_pld_bus2}
    {1792 3392 2368 3392 HREADY_OUT_pld_bus2}
    {1792 1536 1792 3392 HREADY_OUT_pld_bus2}
    {1792 1536 2368 1536 HREADY_OUT_pld_bus2}
    {1344 1536 1792 1536 HREADY_OUT_pld_bus2}
    {1280 1536 1344 1536 HREADY_OUT_pld_bus2}
    {2368 1536 2432 1536 HREADY_OUT_pld_bus2}
    {1664 3520 2368 3520 HRESP_pld_bus2[1:0]}
    {2368 3520 2432 3520 HRESP_pld_bus2[1:0]}
    {1664 1664 1664 3520 HRESP_pld_bus2[1:0]}
    {1664 1664 2368 1664 HRESP_pld_bus2[1:0]}
    {1344 1664 1664 1664 HRESP_pld_bus2[1:0]}
    {1280 1664 1344 1664 HRESP_pld_bus2[1:0]}
    {2368 1664 2432 1664 HRESP_pld_bus2[1:0]}
    {1344 2048 2368 2048 HRDATA_pld_bus2[31:0]}
    {1280 2048 1344 2048 HRDATA_pld_bus2[31:0]}
    {2368 2048 2432 2048 HRDATA_pld_bus2[31:0]}
    {1280 2176 1344 2176 master1_haddress[31:0]}
    {1344 2176 2368 2176 master1_haddress[31:0]}
    {2368 2176 2432 2176 master1_haddress[31:0]}
    {1280 3136 1344 3136 master2_start_trans}
    {1344 3136 2368 3136 master2_start_trans}
    {2368 3136 2432 3136 master2_start_trans}
    {4736 1408 6208 1408 HTRANS_master1[1:0]}
    {4672 1408 4736 1408 HTRANS_master1[1:0]}
    {6208 1408 6272 1408 HTRANS_master1[1:0]}
    {4736 1536 6208 1536 HADDR_master1[31:0]}
    {4672 1536 4736 1536 HADDR_master1[31:0]}
    {6208 1536 6272 1536 HADDR_master1[31:0]}
    {4736 1664 6208 1664 HWRITE_master1}
    {4672 1664 4736 1664 HWRITE_master1}
    {6208 1664 6272 1664 HWRITE_master1}
    {4736 1792 6208 1792 HBURST_master1[2:0]}
    {6208 1792 6272 1792 HBURST_master1[2:0]}
    {4672 1792 4736 1792 HBURST_master1[2:0]}
    {6208 1920 6272 1920 HWDATA_master1[31:0]}
    {4736 1920 6208 1920 HWDATA_master1[31:0]}
    {4672 1920 4736 1920 HWDATA_master1[31:0]}
    {4736 2048 6208 2048 HSIZE_master1[2:0]}
    {6208 2048 6272 2048 HSIZE_master1[2:0]}
    {4672 2048 4736 2048 HSIZE_master1[2:0]}
    {4672 2176 4736 2176 master1_hrdata[31:0]}
    {4736 2176 6208 2176 master1_hrdata[31:0]}
    {6208 2176 6272 2176 master1_hrdata[31:0]}
    {6208 2304 6272 2304 master1_bus_error}
    {4736 2304 6208 2304 master1_bus_error}
    {4672 2304 4736 2304 master1_bus_error}
    {4672 3264 4736 3264 HTRANS_master2[1:0]}
    {4736 3264 6208 3264 HTRANS_master2[1:0]}
    {6208 3264 6272 3264 HTRANS_master2[1:0]}
    {4672 3392 4736 3392 HADDR_master2[31:0]}
    {4736 3392 6208 3392 HADDR_master2[31:0]}
    {6208 3392 6272 3392 HADDR_master2[31:0]}
    {4736 3520 6208 3520 HWRITE_master2}
    {4672 3520 4736 3520 HWRITE_master2}
    {6208 3520 6272 3520 HWRITE_master2}
    {4672 3648 4736 3648 HBURST_master2[2:0]}
    {4736 3648 6208 3648 HBURST_master2[2:0]}
    {6208 3648 6272 3648 HBURST_master2[2:0]}
    {4736 3776 6208 3776 HWDATA_master2[31:0]}
    {4672 3776 4736 3776 HWDATA_master2[31:0]}
    {6208 3776 6272 3776 HWDATA_master2[31:0]}
    {6208 3904 6272 3904 HSIZE_master2[2:0]}
    {4736 3904 6208 3904 HSIZE_master2[2:0]}
    {4672 3904 4736 3904 HSIZE_master2[2:0]}
    {2048 1408 2368 1408 HGRANT_pld_bus2[1]}
    {1984 1408 2048 1408 HGRANT_pld_bus2[1]}
    {2368 1408 2432 1408 HGRANT_pld_bus2[1]}
    {2048 3264 2368 3264 HGRANT_pld_bus2[2]}
    {1984 3264 2048 3264 HGRANT_pld_bus2[2]}
    {2368 3264 2432 3264 HGRANT_pld_bus2[2]}
    {4672 1280 4736 1280 HBUSREQ_pld_bus2[1]}
    {4736 1280 5440 1280 HBUSREQ_pld_bus2[1]}
    {4736 3136 5440 3136 HBUSREQ_pld_bus2[2]}
    {4672 3136 4736 3136 HBUSREQ_pld_bus2[2]}
    {1920 1344 1920 3200 HGRANT_pld_bus2[2:0]}
    {1344 1344 1920 1344 HGRANT_pld_bus2[2:0]}
    {1280 1344 1344 1344 HGRANT_pld_bus2[2:0]}
    {1344 576 5440 576 HBUSREQ_pld_bus2[0]}
    {1280 576 1344 576 HBUSREQ_pld_bus2[0]}
}

