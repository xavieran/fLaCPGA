transcript on
if {[file exists rtl_work]} {
    vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+/home/xavieran/BEngBSc/YEAR\ 5/FYP/fLaCPGA/HardwareEncoder {/home/xavieran/BEngBSc/YEAR 5/FYP/fLaCPGA/HardwareEncoder/GenerateAutocorrelation.v}
vlog -vlog01compat -work work +incdir+/home/xavieran/BEngBSc/YEAR\ 5/FYP/fLaCPGA/HardwareEncoder {/home/xavieran/BEngBSc/YEAR 5/FYP/fLaCPGA/HardwareEncoder/fp_divider.v}
vlog -vlog01compat -work work +incdir+/home/xavieran/BEngBSc/YEAR\ 5/FYP/fLaCPGA/HardwareEncoder {/home/xavieran/BEngBSc/YEAR 5/FYP/fLaCPGA/HardwareEncoder/fp_convert.v}

vlog -vlog01compat -work work +incdir+/home/xavieran/BEngBSc/YEAR\ 5/FYP/fLaCPGA/HardwareEncoder {/home/xavieran/BEngBSc/YEAR 5/FYP/fLaCPGA/HardwareEncoder/GenerateAutocorrelationTB.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneii_ver -L rtl_work -L work -voptargs="+acc"  GenerateAutocorrelationTB


onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /GenerateAutocorrelationTB/clk
add wave -noupdate /GenerateAutocorrelationTB/ena
add wave -noupdate /GenerateAutocorrelationTB/rst
add wave -noupdate /GenerateAutocorrelationTB/sample
add wave -noupdate /GenerateAutocorrelationTB/infile
add wave -noupdate /GenerateAutocorrelationTB/i
add wave -noupdate /GenerateAutocorrelationTB/acf0
add wave -noupdate /GenerateAutocorrelationTB/acf1
add wave -noupdate /GenerateAutocorrelationTB/acf2
add wave -noupdate /GenerateAutocorrelationTB/acf3
add wave -noupdate -radix decimal -childformat {{{/GenerateAutocorrelationTB/ga/dataq[0]} -radix decimal} {{/GenerateAutocorrelationTB/ga/dataq[1]} -radix decimal} {{/GenerateAutocorrelationTB/ga/dataq[2]} -radix decimal} {{/GenerateAutocorrelationTB/ga/dataq[3]} -radix decimal}} -expand -subitemconfig {{/GenerateAutocorrelationTB/ga/dataq[0]} {-radix decimal} {/GenerateAutocorrelationTB/ga/dataq[1]} {-radix decimal} {/GenerateAutocorrelationTB/ga/dataq[2]} {-radix decimal} {/GenerateAutocorrelationTB/ga/dataq[3]} {-radix decimal}} /GenerateAutocorrelationTB/ga/dataq
add wave -noupdate -radix decimal -childformat {{{/GenerateAutocorrelationTB/ga/integer_acf[0]} -radix decimal} {{/GenerateAutocorrelationTB/ga/integer_acf[1]} -radix decimal} {{/GenerateAutocorrelationTB/ga/integer_acf[2]} -radix decimal} {{/GenerateAutocorrelationTB/ga/integer_acf[3]} -radix decimal}} -expand -subitemconfig {{/GenerateAutocorrelationTB/ga/integer_acf[0]} {-radix decimal} {/GenerateAutocorrelationTB/ga/integer_acf[1]} {-radix decimal} {/GenerateAutocorrelationTB/ga/integer_acf[2]} {-radix decimal} {/GenerateAutocorrelationTB/ga/integer_acf[3]} {-radix decimal}} /GenerateAutocorrelationTB/ga/integer_acf
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {55625 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 81
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {169192 ps}

view structure
view signals


run -all
