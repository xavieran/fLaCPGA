onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /RiceStreamReaderTB/i
add wave -noupdate -radix unsigned /RiceStreamReaderTB/j
add wave -noupdate -radix unsigned /RiceStreamReaderTB/DUT/typical_part_size
add wave -noupdate -radix unsigned /RiceStreamReaderTB/DUT/expected_samples
add wave -noupdate -radix unsigned /RiceStreamReaderTB/iClock
add wave -noupdate -radix unsigned /RiceStreamReaderTB/rst
add wave -noupdate -radix unsigned /RiceStreamReaderTB/en
add wave -noupdate -radix unsigned /RiceStreamReaderTB/data
add wave -noupdate -radix unsigned /RiceStreamReaderTB/DUT/procLSBs
add wave -noupdate -radix unsigned /RiceStreamReaderTB/DUT/procMSBs
add wave -noupdate -radix unsigned /RiceStreamReaderTB/DUT/procRiceParam
add wave -noupdate -radix unsigned /RiceStreamReaderTB/DUT/state
add wave -noupdate -radix unsigned /RiceStreamReaderTB/DUT/bits_remaining
add wave -noupdate -radix unsigned /RiceStreamReaderTB/DUT/sample_count
add wave -noupdate -radix unsigned /RiceStreamReaderTB/RiceParam
add wave -noupdate -radix unsigned /RiceStreamReaderTB/Done
add wave -noupdate -radix unsigned /RiceStreamReaderTB/MSB
add wave -noupdate -radix unsigned /RiceStreamReaderTB/LSB
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {570000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 339
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
WaveRestoreZoom {0 ps} {1763311 ps}
