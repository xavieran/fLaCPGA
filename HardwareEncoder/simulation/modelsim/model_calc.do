transcript on
if {[file exists rtl_work]} {
    vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+/home/xavieran/BEngBSc/YEAR\ 5/FYP/fLaCPGA/HardwareEncoder {/home/xavieran/BEngBSc/YEAR 5/FYP/fLaCPGA/HardwareEncoder/ModelSelector.v}
vlog -vlog01compat -work work +incdir+/home/xavieran/BEngBSc/YEAR\ 5/FYP/fLaCPGA/HardwareEncoder {/home/xavieran/BEngBSc/YEAR 5/FYP/fLaCPGA/HardwareEncoder/fp_mult.v}
vlog -vlog01compat -work work +incdir+/home/xavieran/BEngBSc/YEAR\ 5/FYP/fLaCPGA/HardwareEncoder {/home/xavieran/BEngBSc/YEAR 5/FYP/fLaCPGA/HardwareEncoder/fp_add_sub.v}

vlog -vlog01compat -work work +incdir+/home/xavieran/BEngBSc/YEAR\ 5/FYP/fLaCPGA/HardwareEncoder {/home/xavieran/BEngBSc/YEAR 5/FYP/fLaCPGA/HardwareEncoder/ModelSelectorTB.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneii_ver -L rtl_work -L work -voptargs="+acc"  ModelSelectorTB


onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /ModelSelectorTB/ms/ADD_LATENCY
add wave -noupdate /ModelSelectorTB/ms/MULT_LATENCY
add wave -noupdate /ModelSelectorTB/ms/NewModel1
add wave -noupdate /ModelSelectorTB/ms/NewModel2
add wave -noupdate /ModelSelectorTB/ms/ORDER
add wave -noupdate /ModelSelectorTB/ms/TOTAL_LATENCY
add wave -noupdate /ModelSelectorTB/ms/iClock
add wave -noupdate /ModelSelectorTB/ms/iEnable
add wave -noupdate /ModelSelectorTB/ms/add_en
add wave -noupdate /ModelSelectorTB/ms/mult_en
add wave -noupdate /ModelSelectorTB/ms/iReset
add wave -noupdate /ModelSelectorTB/ms/i
add wave -noupdate /ModelSelectorTB/ms/oOnlyOne
add wave -noupdate /ModelSelectorTB/ms/only_one
add wave -noupdate -radix unsigned /ModelSelectorTB/ms/iM
add wave -noupdate -radix hexadecimal /ModelSelectorTB/ms/km
add wave -noupdate -radix unsigned /ModelSelectorTB/ms/m
add wave -noupdate -radix unsigned /ModelSelectorTB/ms/n
add wave -noupdate -radix unsigned /ModelSelectorTB/ms/a
add wave -noupdate -radix unsigned /ModelSelectorTB/ms/b
add wave -noupdate -radix unsigned /ModelSelectorTB/ms/oSel1
add wave -noupdate -radix unsigned /ModelSelectorTB/ms/oSel2
add wave -noupdate -radix unsigned /ModelSelectorTB/ms/dTarget1
add wave -noupdate -radix unsigned /ModelSelectorTB/ms/dTarget2
add wave -noupdate -radix unsigned /ModelSelectorTB/ms/oTarget1
add wave -noupdate -radix unsigned /ModelSelectorTB/ms/oTarget2
add wave -noupdate -radix hexadecimal /ModelSelectorTB/ms/dModel1
add wave -noupdate -radix hexadecimal /ModelSelectorTB/ms/dModel2
add wave -noupdate -radix hexadecimal /ModelSelectorTB/ms/iKm
add wave -noupdate -radix hexadecimal /ModelSelectorTB/ms/iModel1
add wave -noupdate -radix hexadecimal /ModelSelectorTB/ms/iModel2
add wave -noupdate -radix hexadecimal /ModelSelectorTB/ms/mult1
add wave -noupdate -radix hexadecimal /ModelSelectorTB/ms/mult2
add wave -noupdate -radix hexadecimal /ModelSelectorTB/ms/oNewModel1
add wave -noupdate -radix hexadecimal /ModelSelectorTB/ms/oNewModel2
add wave -noupdate /ModelSelectorTB/ms/oDone
add wave -noupdate /ModelSelectorTB/ms/valid
add wave -noupdate /ModelSelectorTB/ms/oValid

TreeUpdate [SetDefaultTree]
quietly wave cursor active 1
configure wave -namecolwidth 312
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
