#create working lib
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work


#compile design files
vcom pc.vhd
vcom instruction_memory.vhd
vcom data_memory.vhd
vcom register_file.vhd
vcom control_unit.vhd
vcom immediate_instruction.vhd
vcom alu_control.vhd
vcom alu.vhd
vcom hazard_detection.vhd
vcom if_id_reg.vhd
vcom id_ex_reg.vhd
vcom ex_mem_reg.vhd
vcom mem_wb_reg.vhd
vcom -2008 cpu.vhd
vcom testbench.vhd

#run the simulation
vsim -t 1ps -novopt work.testbench
run 10000 ns

#integer to binary string converter
proc int_to_bin32 {val} {
    set n [expr {int($val) & 0xFFFFFFFF}]
    set result ""
    for {set i 31} {$i >= 0} {incr i -1} {
        if {($n >> $i) & 1} {
            append result "1"
        } else {
            append result "0"
        }
    }
    return $result
}


#dumping data memory to memory.txt -> this will create a text file that will contain the data memory contents, kind of like a report 
set mem_file [open "memory.txt" w]
set num_words 8192
for {set word_idx 0} {$word_idx < $num_words} {incr word_idx} {
    set base [expr {$word_idx * 4}]
 
    set b0 [examine -decimal /testbench/uut/data_mem_inst/mem($base)]
    set b1 [examine -decimal /testbench/uut/data_mem_inst/mem([expr {$base + 1}])]
    set b2 [examine -decimal /testbench/uut/data_mem_inst/mem([expr {$base + 2}])]
    set b3 [examine -decimal /testbench/uut/data_mem_inst/mem([expr {$base + 3}])]
 
    set word [expr {(($b3 & 0xFF) << 24) | (($b2 & 0xFF) << 16) | (($b1 & 0xFF) << 8) | ($b0 & 0xFF)}]
    puts $mem_file [int_to_bin32 $word]
}
 
close $mem_file
echo "Data memory dumped to memory.txt."


#dumping register file to reg_file.txt -> same logic as above
set reg_file [open "register_file.txt" w]
 
for {set i 0} {$i < 32} {incr i} {
    set val [examine -decimal /testbench/uut/reg_file_inst/registers($i)]
    puts $reg_file [int_to_bin32 $val]
}
 
close $reg_file
echo "Register file dumped to register_file.txt."
 
echo "Simulation complete."
