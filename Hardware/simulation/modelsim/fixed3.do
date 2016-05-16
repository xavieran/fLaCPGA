onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /FixedDecoderOrder3TB/iEnable
add wave -noupdate /FixedDecoderOrder3TB/iReset
add wave -noupdate /FixedDecoderOrder3TB/oData
add wave -noupdate /FixedDecoderOrder3TB/iClock
add wave -noupdate /FixedDecoderOrder3TB/iSample
add wave -noupdate /FixedDecoderOrder3TB/DUT/SampleD1
add wave -noupdate /FixedDecoderOrder3TB/DUT/dataq0
add wave -noupdate /FixedDecoderOrder3TB/DUT/dataq1
add wave -noupdate /FixedDecoderOrder3TB/DUT/dataq2
add wave -noupdate /FixedDecoderOrder3TB/DUT/term1
add wave -noupdate /FixedDecoderOrder3TB/DUT/term2
add wave -noupdate /FixedDecoderOrder3TB/DUT/term3
add wave -noupdate /FixedDecoderOrder3TB/DUT/term4
add wave -noupdate /FixedDecoderOrder3TB/DUT/term3d1
add wave -noupdate /FixedDecoderOrder3TB/DUT/dataq0d2
add wave -noupdate -radix unsigned /FixedDecoderOrder3TB/DUT/warmup_count
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {117162 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 316
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
WaveRestoreZoom {0 ps} {457704 ps}
