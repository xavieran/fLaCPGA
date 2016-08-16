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
add wave -noupdate /GenerateAutocorrelationTB/ga/i
add wave -noupdate /GenerateAutocorrelationTB/ga/iClock
add wave -noupdate /GenerateAutocorrelationTB/ga/iEnable
add wave -noupdate /GenerateAutocorrelationTB/ga/iReset
add wave -noupdate /GenerateAutocorrelationTB/ga/iSample
add wave -noupdate /GenerateAutocorrelationTB/ga/oDone
add wave -noupdate /GenerateAutocorrelationTB/ga/dataq
add wave -noupdate /GenerateAutocorrelationTB/ga/lags
add wave -noupdate /GenerateAutocorrelationTB/ga/integer_acf_work
add wave -noupdate /GenerateAutocorrelationTB/ga/integer_data
add wave -noupdate -expand /GenerateAutocorrelationTB/ga/integer_acf
add wave -noupdate -radix unsigned /GenerateAutocorrelationTB/ga/process_counter
add wave -noupdate -radix unsigned -childformat {{{/GenerateAutocorrelationTB/ga/converter_mux_out[42]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[41]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[40]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[39]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[38]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[37]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[36]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[35]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[34]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[33]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[32]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[31]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[30]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[29]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[28]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[27]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[26]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[25]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[24]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[23]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[22]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[21]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[20]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[19]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[18]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[17]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[16]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[15]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[14]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[13]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[12]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[11]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[10]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[9]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[8]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[7]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[6]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[5]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[4]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[3]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[2]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[1]} -radix unsigned} {{/GenerateAutocorrelationTB/ga/converter_mux_out[0]} -radix unsigned}} -subitemconfig {{/GenerateAutocorrelationTB/ga/converter_mux_out[42]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[41]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[40]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[39]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[38]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[37]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[36]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[35]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[34]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[33]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[32]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[31]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[30]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[29]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[28]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[27]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[26]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[25]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[24]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[23]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[22]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[21]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[20]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[19]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[18]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[17]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[16]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[15]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[14]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[13]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[12]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[11]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[10]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[9]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[8]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[7]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[6]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[5]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[4]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[3]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[2]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[1]} {-radix unsigned} {/GenerateAutocorrelationTB/ga/converter_mux_out[0]} {-radix unsigned}} /GenerateAutocorrelationTB/ga/converter_mux_out
add wave -noupdate -radix unsigned /GenerateAutocorrelationTB/ga/converter_select
add wave -noupdate /GenerateAutocorrelationTB/ga/conv_en
add wave -noupdate -radix hexadecimal /GenerateAutocorrelationTB/ga/floating_data
add wave -noupdate -radix unsigned /GenerateAutocorrelationTB/ga/sample_count
add wave -noupdate /GenerateAutocorrelationTB/ga/div_en
add wave -noupdate -radix hexadecimal /GenerateAutocorrelationTB/ga/numerator
add wave -noupdate -radix hexadecimal /GenerateAutocorrelationTB/ga/denominator
add wave -noupdate -radix hexadecimal /GenerateAutocorrelationTB/ga/result
add wave -noupdate -radix hexadecimal -childformat {{{/GenerateAutocorrelationTB/ga/floating_acf[0]} -radix hexadecimal} {{/GenerateAutocorrelationTB/ga/floating_acf[1]} -radix hexadecimal} {{/GenerateAutocorrelationTB/ga/floating_acf[2]} -radix hexadecimal} {{/GenerateAutocorrelationTB/ga/floating_acf[3]} -radix hexadecimal}} -expand -subitemconfig {{/GenerateAutocorrelationTB/ga/floating_acf[0]} {-radix hexadecimal} {/GenerateAutocorrelationTB/ga/floating_acf[1]} {-radix hexadecimal} {/GenerateAutocorrelationTB/ga/floating_acf[2]} {-radix hexadecimal} {/GenerateAutocorrelationTB/ga/floating_acf[3]} {-radix hexadecimal}} /GenerateAutocorrelationTB/ga/floating_acf
add wave -noupdate /GenerateAutocorrelationTB/ga/start_division
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {82448687 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 375
configure wave -valuecolwidth 100
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
WaveRestoreZoom {81851620 ps} {82528380 ps}

view structure
view signals
run -all

