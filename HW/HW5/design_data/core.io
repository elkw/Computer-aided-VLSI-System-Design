###############################################################
#  Generated by:      Cadence Innovus 17.11-s080_1
#  OS:                Linux x86_64(Host ID cad30)
#  Generated on:      Tue May  9 22:40:52 2023
#  Design:            core
#  Command:           saveIoFile -byOrder -temp core.save.io
###############################################################

(globals
    version = 3
    io_order = default
)
(iopin
    (top
	(pin name="i_clk"	 layer=2 width=0.2000 depth=0.7200 place_status=placed  )
	(pin name="i_rst_n"	 layer=2 width=0.2000 depth=0.7200 place_status=placed  )
	(pin name="i_op_valid"	 layer=2 width=0.2000 depth=0.7200 place_status=placed  )
	(pin name="i_op_mode[3]"	 layer=2 width=0.2000 depth=0.7200 place_status=placed  )
	(pin name="i_op_mode[2]"	 layer=2 width=0.2000 depth=0.7200 place_status=placed  )
	(pin name="i_op_mode[1]"	 layer=2 width=0.2000 depth=0.7200 place_status=placed  )
	(pin name="i_op_mode[0]"	 layer=2 width=0.2000 depth=0.7200 place_status=placed  )
	(pin name="o_op_ready"	 layer=2 width=0.2000 depth=0.7200 place_status=placed  )
	(pin name="i_in_valid"	 layer=2 width=0.2000 depth=0.7200 place_status=placed  )
    (inst name="ipad_CoreVDD1"      cell="PVDD1DGZ")
	(inst name="ipad_CoreVSS1"      cell="PVSS1DGZ")
	)
    (left
	(pin name="i_in_data[7]"	 layer=3 width=0.2000 depth=0.7200 place_status=placed  )
	(pin name="i_in_data[6]"	 layer=3 width=0.2000 depth=0.7200 place_status=placed  )
	(pin name="i_in_data[5]"	 layer=3 width=0.2000 depth=0.7200 place_status=placed  )
	(pin name="i_in_data[4]"	 layer=3 width=0.2000 depth=0.7200 place_status=placed  )
	(pin name="i_in_data[3]"	 layer=3 width=0.2000 depth=0.7200 place_status=placed  )
	(pin name="i_in_data[2]"	 layer=3 width=0.2000 depth=0.7200 place_status=placed  )
	(pin name="i_in_data[1]"	 layer=3 width=0.2000 depth=0.7200 place_status=placed  )
	(pin name="i_in_data[0]"	 layer=3 width=0.2000 depth=0.7200 place_status=placed  )
    (inst name="ipad_CoreVDD2"       cell="PVDD1DGZ")
	(inst name="ipad_CoreVSS2"       cell="PVSS1DGZ")
	)
    (bottom
	(pin name="o_in_ready"	 layer=3 width=0.2000 depth=0.7200 place_status=placed  )
	(pin name="o_out_valid"	 layer=2 width=0.2000 depth=0.7200 place_status=placed  )
	(pin name="o_out_data[13]"	 layer=2 width=0.2000 depth=0.7200 place_status=placed  )
	(pin name="o_out_data[12]"	 layer=2 width=0.2000 depth=0.7200 place_status=placed  )
	(pin name="o_out_data[11]"	 layer=2 width=0.2000 depth=0.7200 place_status=placed  )
	(pin name="o_out_data[10]"	 layer=2 width=0.2000 depth=0.7200 place_status=placed  )
	(pin name="o_out_data[9]"	 layer=2 width=0.2000 depth=0.7200 place_status=placed  )
	(pin name="o_out_data[8]"	 layer=2 width=0.2000 depth=0.7200 place_status=placed  )
	(inst name="ipad_IOVDD1"        cell="PVDD2POC")
	(inst name="ipad_IOVSS1"        cell="PVSS2DGZ")
	)
    (right
	(pin name="o_out_data[7]"	 layer=2 width=0.2000 depth=0.7200 place_status=placed  )
	(pin name="o_out_data[6]"	 layer=2 width=0.2000 depth=0.7200 place_status=placed  )
	(pin name="o_out_data[5]"	 layer=3 width=0.2000 depth=0.7200 place_status=placed  )
	(pin name="o_out_data[4]"	 layer=3 width=0.2000 depth=0.7200 place_status=placed  )
	(pin name="o_out_data[3]"	 layer=3 width=0.2000 depth=0.7200 place_status=placed  )
	(pin name="o_out_data[2]"	 layer=3 width=0.2000 depth=0.7200 place_status=placed  )
	(pin name="o_out_data[1]"	 layer=3 width=0.2000 depth=0.7200 place_status=placed  )
	(pin name="o_out_data[0]"	 layer=3 width=0.2000 depth=0.7200 place_status=placed  )
    (inst name="ipad_IOVDD2"        cell="PVDD2DGZ")
	(inst name="ipad_IOVSS2"        cell="PVSS2DGZ")
	)
	(topright
		(inst name="CORNER0"        cell="PCORNERDGZ")
	)
	(topleft
		(inst name="CORNER1"        cell="PCORNERDGZ")
	)
	(bottomright
		(inst name="CORNER2"        cell="PCORNERDGZ")
	)
	(bottomleft
		(inst name="CORNER3"        cell="PCORNERDGZ")
	)
)
