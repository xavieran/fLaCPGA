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
add wave -noupdate /GenerateAutocorrelationTB/ga/BLOCK_SIZE
add wave -noupdate /GenerateAutocorrelationTB/ga/CONVERTER_DELAY
add wave -noupdate /GenerateAutocorrelationTB/ga/DIVIDER_DELAY
add wave -noupdate /GenerateAutocorrelationTB/ga/LAGS
add wave -noupdate /GenerateAutocorrelationTB/ga/acf
add wave -noupdate /GenerateAutocorrelationTB/ga/conv_en
add wave -noupdate /GenerateAutocorrelationTB/ga/conversion_counter
add wave -noupdate /GenerateAutocorrelationTB/ga/dataq
add wave -noupdate /GenerateAutocorrelationTB/ga/denominator
add wave -noupdate /GenerateAutocorrelationTB/ga/div_en
add wave -noupdate /GenerateAutocorrelationTB/ga/division_counter
add wave -noupdate /GenerateAutocorrelationTB/ga/division_step
add wave -noupdate -radix unsigned -childformat {{{/GenerateAutocorrelationTB/ga/floating_acf[0]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/floating_acf[1]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/floating_acf[2]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/floating_acf[3]} -radix unsigned}} -expand -subitemconfig {{/GenerateAutocorrelationTB/ga/floating_acf[0]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/floating_acf[1]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/floating_acf[2]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/floating_acf[3]} {-radix unsigned}} /GenerateAutocorrelationTB/ga/floating_acf
add wave -noupdate /GenerateAutocorrelationTB/ga/i
add wave -noupdate /GenerateAutocorrelationTB/ga/iClock
add wave -noupdate /GenerateAutocorrelationTB/ga/iEnable
add wave -noupdate /GenerateAutocorrelationTB/ga/iReset
add wave -noupdate /GenerateAutocorrelationTB/ga/iSample
add wave -noupdate -radix decimal -childformat {{{/GenerateAutocorrelationTB/ga/integer_acf[0]} -radix decimal} {{/GenerateAutocorrelationTB/ga/integer_acf[1]} -radix decimal} {{/GenerateAutocorrelationTB/ga/integer_acf[2]} -radix decimal} {{/GenerateAutocorrelationTB/ga/integer_acf[3]} -radix decimal}} -expand -subitemconfig {{/GenerateAutocorrelationTB/ga/integer_acf[0]} {-radix decimal} {/GenerateAutocorrelationTB/ga/integer_acf[1]} {-radix decimal} {/GenerateAutocorrelationTB/ga/integer_acf[2]} {-radix decimal} {/GenerateAutocorrelationTB/ga/integer_acf[3]} {-radix decimal}} /GenerateAutocorrelationTB/ga/integer_acf
add wave -noupdate -radix decimal /GenerateAutocorrelationTB/ga/integer_data
add wave -noupdate -radix unsigned /GenerateAutocorrelationTB/ga/floating_data
add wave -noupdate -radix unsigned /GenerateAutocorrelationTB/ga/numerator
add wave -noupdate /GenerateAutocorrelationTB/ga/oACF0
add wave -noupdate /GenerateAutocorrelationTB/ga/oACF1
add wave -noupdate /GenerateAutocorrelationTB/ga/oACF2
add wave -noupdate /GenerateAutocorrelationTB/ga/oACF3
add wave -noupdate /GenerateAutocorrelationTB/ga/oDone
add wave -noupdate /GenerateAutocorrelationTB/ga/result
add wave -noupdate /GenerateAutocorrelationTB/ga/sample_count
TreeUpdate [SetDefaultTree]
quietly wave cursor active 1
configure wave -namecolwidth 390
configure wave -valuecolwidth 257
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

view structure
view signals


run -all