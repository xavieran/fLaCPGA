onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /RiceStreamReader2TB/iClock
add wave -noupdate /RiceStreamReader2TB/rst
add wave -noupdate /RiceStreamReader2TB/en
add wave -noupdate -radix unsigned /RiceStreamReader2TB/rice_param
add wave -noupdate -radix binary /RiceStreamReader2TB/data
add wave -noupdate /RiceStreamReader2TB/done
add wave -noupdate -radix unsigned /RiceStreamReader2TB/DUT/procMSBs
add wave -noupdate -radix unsigned /RiceStreamReader2TB/DUT/procLSBs
add wave -noupdate -radix unsigned /RiceStreamReader2TB/DUT/rem_bits
add wave -noupdate -radix unsigned /RiceStreamReader2TB/DUT/state
add wave -noupdate -radix unsigned /RiceStreamReader2TB/MSB
add wave -noupdate -radix unsigned /RiceStreamReader2TB/LSB
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {281199 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 292
configure wave -valuecolwidth 130
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
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {525 ns}
