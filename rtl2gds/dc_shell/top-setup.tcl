
set BRICK_RESULTS				[getenv "BRICK_RESULTS"];
set TSMC_DIR                    [getenv "TSMC_DIR"];
set PROJECT_ROOT                [getenv "PROJECT_ROOT"];

set DESIGN_NAME                 "synapse";      # The name of the top-level design.

#############################################################
# The following variables will be set automatically during
# 'icdc setup' -> 'commit setup' execution
# Manual changes could be made, but will be overwritten
# when 'icdc setup' is executed again
#
##############################################################
# START Auto Setup Section

# Additional search path to be added
# to the default search path
# The search paths belong to the following libraries:
# * core standard cell library
# * analog I/O standard cell library
# * digital I/O standard cell library
# * SRAM macro library
# * full custom macro libraries
set ADDITIONAL_SEARCH_PATHS	[list \
    "$TSMC_DIR/digital/Front_End/timing_power_noise/NLDM/tcbn65lp_200a" \
    "$TSMC_DIR/digital/Front_End/timing_power_noise/NLDM/tpdn65lpnv2_140b" \
    "$TSMC_DIR/digital/Front_End/timing_power_noise/NLDM/tpan65lpgv2_140c" \
	"/cad/libs/tsmc/sram/ts1n65lpa4096x32m16_140a/SYNOPSYS" \
	"/cad/libs/tsmc/sram/tsdn65lpa1024x32m4s_200b/SYNOPSYS" \
	"/cad/libs/tsmc/sram/ts5n65lpa32x128m2_140b/SYNOPSYS" \
	"$PROJECT_ROOT/hicann-dls/units/generic_elements/abstract" \
	"$BRICK_RESULTS/../results" \
]

# Target technology logical libraries
set TARGET_LIBRARY_FILES	[list \
    "tcbn65lpwc.db" \
    "tpdn65lpnv2wc.db" \
		"tpan65lpgv2wc.db" \
	"ts5n65lpa32x128m2_140b_tt1p2v40c.db" \
	"tsdn65lpa1024x32m4s_200b_tt1p2v40c.db" \
	"ts1n65lpa4096x32m16_140a_tt1p2v40c.db" \
]
#    "generic_elements_esd_PDB1AC_lr.db" \
#    "generic_elements_esd_PDB1A_lr.db" \
#    "generic_elements_esd_PDB1A_hr.db" \
#    "generic_elements_esd_PDB3AC_lr.db" \
#    "generic_elements_esd_PDB3AC_hr.db" \
#    "generic_elements_esd_PDB3A_lr.db" \
#    "generic_elements_esd_PDB3A_hr.db" \


# List of max min library pairs "max1 min1  max2 min2"
set MIN_LIBRARY_FILES	[list \
    "tcbn65lpwc.db"    "tcbn65lpbc.db" \
    "tpdn65lpnv2wc.db" "tpdn65lpnv2bc.db" \
]

# END Auto Setup Section
##############################################################

# Extra link logical libraries
set ADDITIONAL_LINK_LIB_FILES [list \

]


##############################################################
# Topo Mode Settings
# no auto setup implemented so far
# please make necessary modification
#
set MW_REFERENCE_LIB_DIRS         "$TSMC_DIR/digital/Back_End/milkyway/tcbn65lp_200a/frame_only/tcbn65lp";             # Milkyway reference libraries
set TECH_FILE                     "$TSMC_DIR/digital/Back_End/milkyway/tcbn65lp_200a/techfiles/tsmcn65_9lmT2.tf";  			# Milkyway technology file
set MAP_FILE                      "$TSMC_DIR/digital/Back_End/milkyway/tcbn65lp_200a/techfiles/tluplus/star.map_9M"; 			# Mapping file for TLUplus
set TLUPLUS_MAX_FILE              "$TSMC_DIR/digital/Back_End/milkyway/tcbn65lp_200a/techfiles/tluplus/cln65lp_1p09m+alrdl_rcworst_top2.tluplus";          	# Max TLUplus file
set TLUPLUS_MIN_FILE              "$TSMC_DIR/digital/Back_End/milkyway/tcbn65lp_200a/techfiles/tluplus/cln65lp_1p09m+alrdl_rcbest_top2.tluplus";         	# Min TLUplus file
set MW_POWER_NET                  "";     		#
set MW_POWER_PORT                 "";      	    #
set MW_GROUND_NET                 "";      	    #
set MW_GROUND_PORT                "";      	    #


