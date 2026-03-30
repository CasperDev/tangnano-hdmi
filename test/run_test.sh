#!/bin/bash
VIEW="$1"

dsim ../src/gen_video.sv test.sv -top test_tb +acc+b
# --- Otwórz GTKWave, jeśli proszono ---
if [ "$VIEW" = "view" ]; then
	(nohup gtkwave --rcvar 'fontname_signals Monospace 15' --rcvar 'fontname_waves Monospace 11' "test.vcd" "test.gtkw" >/dev/null 2>&1 & disown)
fi
