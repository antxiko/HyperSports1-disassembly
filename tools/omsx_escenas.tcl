# omsx_escenas.tcl - Vuelca la VRAM de las CUATRO pruebas para que las escenas
# de la web se puedan dibujar desde la ROM y cotejarse contra lo que el MSX
# tiene de verdad en la memoria de video.
#
# No hace falta jugar: la demo de atraccion juega las cuatro pruebas sola desde
# el encendido, y es DETERMINISTA -tres pasadas independientes dieron los mismos
# instantes al centesimo-, asi que basta con esperar al segundo apuntado de cada
# una. Lo que sale de aqui es el MAPA DE CASILLAS y los sprites; los dibujos
# (patrones y colores) salen de la ROM, y tools/escenas.py comprueba que
# coinciden byte a byte con este volcado.
#
# NO se sacan capturas de pantalla, y no por descuido: el `screenshot` de
# openMSX va por detras del guion y no coincide con la lectura de la VRAM del
# mismo instante. Comprobado dos veces, y con la maquina en pausa: pidiendo la
# escena del trampolin salio la pantalla de la prueba ANTERIOR, y pidiendo la de
# la barra fija salio el logotipo del arranque. La VRAM, que se lee sincrona con
# `debug read_block`, si es del instante que se pide.
#
#   "C:/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 \
#       -cart hypersports1.rom -script tools/omsx_escenas.tcl
#
# Deja en work/omsx/escenas un escena_<n>.vram de 16384 bytes por escena.

set ::DIR "C:/Users/Antxiko/Documents/DES_ASM/HYPERSPORTS1_DISAM/work/omsx/escenas"
file mkdir $::DIR

# El instante de cada escena, elegido mirando tandas de volcados: la pantalla
# montada del todo y el atleta en la postura que mejor cuenta la prueba.
#   0 DIVING          cayendo de cabeza al agua, con la mesa de jueces detras
#   1 DIVING          el chapoteo de la entrada, un segundo despues
#   2 LONG HORSE      la carrera hacia el potro, con el trampolin de batida
#   3 TRAMPOLINE      el atleta agachado en la cama elastica
#   4 HORIZONTAL BAR  el gimnasta en pleno giro alrededor de la barra
set ::CUANDO {0 29.5 1 30.5 2 62.5 3 96.0 4 164.0}

set ::f [open "$::DIR/escenas.txt" w]
set ::pendientes {0 1 2 3 4}

proc lee {a} { return [debug read memory $a] }

proc saca {n} {
    set g [open [format "%s/escena_%d.vram" $::DIR $n] w]
    fconfigure $g -translation binary
    puts -nonewline $g [debug read_block VRAM 0 16384]
    close $g
    # los ocho registros del VDP: de ellos sale donde vive cada tabla y que los
    # sprites son de 16x16 sin ampliar (R1 = 0xE2)
    set r ""
    for {set i 0} {$i < 8} {incr i} { append r [format "%02X " [debug read "VDP regs" $i]] }
    puts $::f [format "escena_%d  t=%8.3f  E000=%02X E052=%02X E183=%02X  regs= %s" \
        $n [machine_info time] [lee 0xE000] [lee 0xE052] [lee 0xE183] $r]
    flush $::f
}

# La fuente del marcador NO esta en el cartucho: 0x43BF la copia de la ROM del
# MSX, tomando el puntero CGTBL de 0x0004 y saltandose 0x180 bytes para empezar
# en el caracter '0'. Se vuelcan esos 0x180 bytes -48 caracteres- para poder
# cotejarlos contra los que aparecen en la VRAM.
proc saca_fuente {} {
    set cgtbl [expr {[debug read memory 0x0004] | ([debug read memory 0x0005] << 8)}]
    set g [open "$::DIR/fuente_bios.bin" w]
    fconfigure $g -translation binary
    puts -nonewline $g [debug read_block memory [expr {$cgtbl + 0x180}] 0x180]
    close $g
    puts $::f [format "fuente_bios.bin  CGTBL=0x%04X  desde 0x%04X, 384 bytes" \
        $cgtbl [expr {$cgtbl + 0x180}]]
    flush $::f
}

proc tic {} {
    after time 0.25 tic
    if {[catch {
        set t [machine_info time]
        set quedan {}
        foreach {n cuando} $::CUANDO {
            if {[lsearch $::pendientes $n] < 0} continue
            if {$t >= $cuando} { saca $n } else { lappend quedan $n }
        }
        set ::pendientes $quedan
        if {[llength $::pendientes] == 0} { saca_fuente ; close $::f ; exit }
    } err]} { puts $::f "FALLO $err" ; flush $::f }
}

set throttle off
after time 0.25 tic
after realtime 600 { exit }
