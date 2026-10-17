# omsx_posturas.tcl - Que fotogramas del atleta usa cada prueba.
#
# El bloque posturas_atleta (0x53EC-0x614C) son 3425 bytes de tiras encadenadas
# que solo lee DIBUJA_ATLETA, con su propio descompresor de 0x69FE. Aqui se pone
# un punto de observacion de LECTURA sobre todo el rango y se apunta, por prueba
# (0xE052 y 3), que direcciones se leen Y DESDE QUE PC.
#
# El PC es lo que da valor a la medida, porque separa los bytes por su papel:
# 0x69FE lee las CUENTAS, 0x6A09 los bytes literales y 0x6A12 el byte que se
# repite. Cotejar el conjunto de cuentas medido contra el que sale de trocear el
# bloque en Python es lo que demuestra que el formato esta bien leido. (Lo que NO
# demuestra nada es que las tiras "encajen clavadas" al final del bloque:
# empezando en cualquier byte tambien encajan, comprobado.)
#
# El reparto se hace por 0xE052 leido en el propio callback, no por el reloj: la
# atraccion encadena las cuatro pruebas y separarlas por tiempo seria adivinar.
#
#   "C:/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 \
#       -cart hypersports1.rom -script tools/omsx_posturas.tcl
set ::SAL "C:/Users/Antxiko/Documents/DES_ASM/desensamblados/HYPERSPORTS1_DISAM/work/omsx/posturas.txt"
array set ::visto {}
set ::n 0

# callback BARATO: una lectura de RAM y un set de array. El rango son 3425 bytes
# y se leen cientos de miles de veces, asi que aqui no se formatea nada.
proc cae {addr} {
    set ev [expr {[debug read memory 0xE052] & 3}]
    set ::visto([expr {$addr | ($ev << 16) | ([reg PC] << 20)}]) 1
    incr ::n
}

debug set_watchpoint read_mem {0x53EC 0x614C} {} { cae $::wp_last_address }

# Control: el vector de interrupcion de la ROM. Si esto sale a cero, la medida
# no vale y los ceros de arriba no son datos.
set ::n38 0
debug set_bp 0x0038 {} { incr ::n38 }

proc informe {} {
    set f [open $::SAL w]
    puts $f "t=[machine_info time]  lecturas=$::n  control_0x0038=$::n38"
    puts $f "# prueba, direccion del bloque leida, y PC que la leyo"
    foreach k [lsort -integer [array names ::visto]] {
        puts $f [format "%d 0x%04X 0x%04X" [expr {($k >> 16) & 0xF}]             [expr {$k & 0xFFFF}] [expr {($k >> 20) & 0xFFFF}]]
    }
    close $f
    exit
}

set throttle off
after time 230 informe
after realtime 600 { exit }
