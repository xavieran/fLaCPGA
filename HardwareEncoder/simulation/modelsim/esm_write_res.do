transcript on
if {[file exists rtl_work]} {
    vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+/home/xavieran/BEngBSc/YEAR\ 5/FYP/fLaCPGA/HardwareEncoder {/home/xavieran/BEngBSc/YEAR 5/FYP/fLaCPGA/HardwareEncoder/ChooseBestRice.v}
vlog -vlog01compat -work work +incdir+/home/xavieran/BEngBSc/YEAR\ 5/FYP/fLaCPGA/HardwareEncoder {/home/xavieran/BEngBSc/YEAR 5/FYP/fLaCPGA/HardwareEncoder/EncodingStateMachine.v}
vlog -vlog01compat -work work +incdir+/home/xavieran/BEngBSc/YEAR\ 5/FYP/fLaCPGA/HardwareEncoder {/home/xavieran/BEngBSc/YEAR 5/FYP/fLaCPGA/HardwareEncoder/RiceEncoder.v}
vlog -vlog01compat -work work +incdir+/home/xavieran/BEngBSc/YEAR\ 5/FYP/fLaCPGA/HardwareEncoder {/home/xavieran/BEngBSc/YEAR 5/FYP/fLaCPGA/HardwareEncoder/FixedEncoderOrder0.v}
vlog -vlog01compat -work work +incdir+/home/xavieran/BEngBSc/YEAR\ 5/FYP/fLaCPGA/HardwareEncoder {/home/xavieran/BEngBSc/YEAR 5/FYP/fLaCPGA/HardwareEncoder/FixedEncoderOrder1.v}
vlog -vlog01compat -work work +incdir+/home/xavieran/BEngBSc/YEAR\ 5/FYP/fLaCPGA/HardwareEncoder {/home/xavieran/BEngBSc/YEAR 5/FYP/fLaCPGA/HardwareEncoder/FixedEncoderOrder2.v}
vlog -vlog01compat -work work +incdir+/home/xavieran/BEngBSc/YEAR\ 5/FYP/fLaCPGA/HardwareEncoder {/home/xavieran/BEngBSc/YEAR 5/FYP/fLaCPGA/HardwareEncoder/FixedEncoderOrder3.v}
vlog -vlog01compat -work work +incdir+/home/xavieran/BEngBSc/YEAR\ 5/FYP/fLaCPGA/HardwareEncoder {/home/xavieran/BEngBSc/YEAR 5/FYP/fLaCPGA/HardwareEncoder/FixedEncoderOrder4.v}
vlog -vlog01compat -work work +incdir+/home/xavieran/BEngBSc/YEAR\ 5/FYP/fLaCPGA/HardwareEncoder {/home/xavieran/BEngBSc/YEAR 5/FYP/fLaCPGA/HardwareEncoder/ChooseBestFixed.v}

vlog -vlog01compat -work work +incdir+/home/xavieran/BEngBSc/YEAR\ 5/FYP/fLaCPGA/HardwareEncoder {/home/xavieran/BEngBSc/YEAR 5/FYP/fLaCPGA/HardwareEncoder/EncodingStateMachineTB.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneii_ver -L rtl_work -L work -voptargs="+acc"  EncodingStateMachineTB


onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /EncodingStateMachineTB/clk
add wave -noupdate /EncodingStateMachineTB/ena
add wave -noupdate /EncodingStateMachineTB/rst
add wave -noupdate /EncodingStateMachineTB/sample
add wave -noupdate /EncodingStateMachineTB/infile
add wave -noupdate /EncodingStateMachineTB/i
add wave -noupdate /EncodingStateMachineTB/ram_sample_q
add wave -noupdate /EncodingStateMachineTB/ram_sample_a
add wave -noupdate /EncodingStateMachineTB/sample_we
add wave -noupdate -radix unsigned /EncodingStateMachineTB/ESM/best_rice_param
add wave -noupdate /EncodingStateMachineTB/ESM/state
add wave -noupdate /EncodingStateMachineTB/ESM/best_sample
add wave -noupdate /EncodingStateMachineTB/ESM/best_fixed_encoder
add wave -noupdate /EncodingStateMachineTB/ESM/best_rice_param
add wave -noupdate /EncodingStateMachineTB/ESM/best_msb
add wave -noupdate /EncodingStateMachineTB/ESM/best_lsb
add wave -noupdate /EncodingStateMachineTB/ESM/cbr_enable
add wave -noupdate /EncodingStateMachineTB/ESM/cbr_reset
add wave -noupdate /EncodingStateMachineTB/ESM/choose_enable
add wave -noupdate /EncodingStateMachineTB/ESM/choose_reset
add wave -noupdate /EncodingStateMachineTB/ESM/encoder_enable
add wave -noupdate /EncodingStateMachineTB/ESM/encoder_reset
add wave -noupdate /EncodingStateMachineTB/ESM/rice_enc_reset

TreeUpdate [SetDefaultTree]
quietly wave cursor active 1
configure wave -namecolwidth 305
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

view structure
view signals
run -all
