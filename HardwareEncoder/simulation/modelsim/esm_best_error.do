transcript on
if {[file exists rtl_work]} {
    vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+/home/xavieran/BEngBSc/YEAR\ 5/FYP/fLaCPGA/HardwareEncoder {/home/xavieran/BEngBSc/YEAR 5/FYP/fLaCPGA/HardwareEncoder/EncodingStateMachine.v}
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
add wave -noupdate -radix unsigned /EncodingStateMachineTB/ram_sample_a
add wave -noupdate /EncodingStateMachineTB/sample_we
add wave -noupdate /EncodingStateMachineTB/ESM/iRamReadData
add wave -noupdate /EncodingStateMachineTB/ESM/cbf/FE0_error
add wave -noupdate /EncodingStateMachineTB/ESM/cbf/FE1_error
add wave -noupdate /EncodingStateMachineTB/ESM/cbf/FE2_error
add wave -noupdate /EncodingStateMachineTB/ESM/cbf/FE3_error
add wave -noupdate /EncodingStateMachineTB/ESM/cbf/FE4_error
add wave -noupdate /EncodingStateMachineTB/ESM/best
TreeUpdate [SetDefaultTree]
quietly wave cursor active 1
configure wave -namecolwidth 348
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