onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /FixedDecoderTB/iClock
add wave -noupdate /FixedDecoderTB/iEnable
add wave -noupdate /FixedDecoderTB/iReset
add wave -noupdate -radix unsigned /FixedDecoderTB/iOrder
add wave -noupdate -radix unsigned /FixedDecoderTB/DUT/warmup_count
add wave -noupdate /FixedDecoderTB/iSample
add wave -noupdate /FixedDecoderTB/oData
add wave -noupdate -expand /FixedDecoderTB/DUT/dataq
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {330000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 241
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
WaveRestoreZoom {0 ps} {976216 ps}
