onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /ResidualDecoderTB/WriteAddr
add wave -noupdate -radix unsigned /ResidualDecoderTB/iData
add wave -noupdate -radix unsigned /ResidualDecoderTB/file
add wave -noupdate -radix unsigned /ResidualDecoderTB/hi
add wave -noupdate -radix unsigned /ResidualDecoderTB/lo
add wave -noupdate -radix unsigned /ResidualDecoderTB/i
add wave -noupdate -radix unsigned /ResidualDecoderTB/samples_read
add wave -noupdate -radix unsigned /ResidualDecoderTB/clk
add wave -noupdate -radix unsigned /ResidualDecoderTB/rst
add wave -noupdate -radix unsigned /ResidualDecoderTB/ena
add wave -noupdate -radix unsigned /ResidualDecoderTB/wren
add wave -noupdate -radix unsigned /ResidualDecoderTB/Done
add wave -noupdate -radix unsigned /ResidualDecoderTB/block_size
add wave -noupdate -radix unsigned /ResidualDecoderTB/predictor_order
add wave -noupdate -radix unsigned /ResidualDecoderTB/partition_order
add wave -noupdate -radix hexadecimal /ResidualDecoderTB/RamData
add wave -noupdate -radix unsigned /ResidualDecoderTB/ReadAddr
add wave -noupdate -radix unsigned /ResidualDecoderTB/DUT/rs/expected_samples
add wave -noupdate -radix unsigned /ResidualDecoderTB/DUT/rs/sample_count
add wave -noupdate -radix binary /ResidualDecoderTB/DUT/data_buffer
add wave -noupdate -radix unsigned /ResidualDecoderTB/DUT/curr_bit
add wave -noupdate -radix unsigned /ResidualDecoderTB/oData
add wave -noupdate -radix unsigned /ResidualDecoderTB/DUT/LSBs
add wave -noupdate -radix unsigned /ResidualDecoderTB/DUT/MSBs
add wave -noupdate -radix unsigned /ResidualDecoderTB/DUT/RiceParam
add wave -noupdate -radix unsigned /ResidualDecoderTB/DUT/rs_done
add wave -noupdate -radix unsigned /ResidualDecoderTB/DUT/rs_idata
add wave -noupdate -radix unsigned /ResidualDecoderTB/DUT/rs/state
add wave -noupdate -radix unsigned /ResidualDecoderTB/DUT/rs/bits_remaining
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {115752656 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 346
configure wave -valuecolwidth 141
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
WaveRestoreZoom {115705039 ps} {115834717 ps}
