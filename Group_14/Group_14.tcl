################################################################################
# ECE M216A Project - Group 14
# Logic Synthesis Script (Updated based on Reference)
################################################################################

# 1. CLEANUP & SETUP
# ------------------------------------------------------------------------------
remove_design -all

# Create WORK directory if it doesn't exist (Critical for this library setup)
file mkdir WORK
define_design_lib WORK -path ./WORK
set alib_library_analysis_path "./alib-52/"

# 2. LIBRARY SETUP (Copied from your reference file)
# ------------------------------------------------------------------------------
# Add search paths for technology libs
set search_path "$search_path . /w/apps4/Synopsys/TSMC/CAD_TSMC-16-ADFP-FFC_Muse/Executable_Package/Collaterals/IP/stdcell/N16ADFP_StdCell/NLDM"

# Target Library: Slow corner (Worst case for Setup time)
set target_library "N16ADFP_StdCellss0p72v125c.db"

# Link Library: Includes both Fast (for Hold) and Slow (for Setup) corners
set link_library "* N16ADFP_StdCellff0p88vm40c.db N16ADFP_StdCellss0p72v125c.db dw_foundation.sldb"
set synthetic_library "dw_foundation.sldb"

# Set Minimum Library for Hold Time Analysis (Fast corner)
set_min_library "N16ADFP_StdCellff0p88vm40c.db" -min_version "N16ADFP_StdCellss0p72v125c.db"

# 3. READ DESIGN
# ------------------------------------------------------------------------------
analyze -format verilog {M216A_TopModule.v}
set DESIGN_NAME M216A_TopModule

elaborate $DESIGN_NAME
current_design $DESIGN_NAME
link

# Set Operating Conditions: Mix of Min (Fast) and Max (Slow)
set_operating_conditions -min ff0p88vm40c -max ss0p72v125c

# 4. CONSTRAINTS (Project Req: 500MHz)
# ------------------------------------------------------------------------------
set Tclk 2.0  ;# 500MHz = 2.0ns
set TCU  0.1  ;# Clock Uncertainty

# I/O Delays (Scaled slightly for 2ns clock, kept proportional to reference)
set IN_DEL 0.2
set IN_DEL_MIN 0.1
set OUT_DEL 0.2
set OUT_DEL_MIN 0.1
set ALL_IN_BUT_CLK [remove_from_collection [all_inputs] "clk"]

# Clock Definition
create_clock -name "clk" -period $Tclk [get_ports "clk"]
set_fix_hold clk
set_dont_touch_network [get_clocks "clk"]
set_clock_uncertainty $TCU [get_clocks "clk"]

# I/O Constraints
set_input_delay $IN_DEL -clock "clk" $ALL_IN_BUT_CLK
set_input_delay -min $IN_DEL_MIN -clock "clk" $ALL_IN_BUT_CLK
set_output_delay $OUT_DEL -clock "clk" [all_outputs]
set_output_delay -min $OUT_DEL_MIN -clock "clk" [all_outputs]

# Area Constraint
set_max_area 0.0

# 5. COMPILE STRATEGY (Optimization)
# ------------------------------------------------------------------------------
# Flatten hierarchy for better optimization (Reference strategy)
ungroup -flatten -all
uniquify

# Step 1: Basic compilation
compile -only_design_rule

# Step 2: High effort optimization (Area/Power/Setup)
compile -map high -boundary_optimization

# Step 3: Fix Hold Time Violations (Critical!)
compile -only_hold_time

# 6. GENERATE REPORTS (Group_14 Naming)
# ------------------------------------------------------------------------------
check_design > Group_14.CheckDesign
check_timing > Group_14.CheckTiming

# Timing Reports
report_timing -path full -delay min -max_paths 10 -nworst 2 > Group_14.TimingHold
report_timing -path full -delay max -max_paths 10 -nworst 2 > Group_14.TimingSetup

# Area & Power Reports
report_area -hierarchy > Group_14.Area
report_power -hier -hier_level 2 > Group_14.Power

# Constraint Violations (check this if logic fails)
report_constraint -verbose > Group_14.Constraint

# 7. OUTPUT FILES
# ------------------------------------------------------------------------------
# Write Gate-Level Netlist (Required for future PrimeTime use if needed)
write -hierarchy -format verilog -output M216A_TopModule_Group14.vg
# Write SDC constraints
write_sdc M216A_TopModule_Group14.sdc

puts "Synthesis Finished for Group 14!"
exit