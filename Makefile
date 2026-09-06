# Hyper Sports 1 (Konami, MSX1) - desensamblado
#
# El orden de las cosas: trazar el flujo -> generar el listado -> comprobar que
# vuelve a dar la ROM byte a byte -> las comprobaciones que el reensamblado NO
# cubre.
#
# La ROM no se distribuye. Hace falta en la raiz como hypersports1.rom, y
# `make comprueba` verifica el sha256.

ROM      = hypersports1.rom
SHA      = 440dae57676a98b5a3dd29f3e97b9c83a8cbe58a3d3f2172c6072d07e6f00754
SRC      = src
WORK     = work
ORG      = 0x4000
OPENMSX  = C:/Program Files/openMSX/openmsx.exe
TITULO   = HYPER SPORTS 1 - Konami - MSX1 - cartucho RC-715 de 16 KB en la pagina 1

all: listado verify sanity test

$(ROM):
	@echo "=================================================================="
	@echo " Falta $(ROM), y este repositorio NO lo distribuye."
	@echo ""
	@echo " Es Hyper Sports 1 (Konami, RC-715) para MSX, 16384 bytes exactos."
	@echo " Ponlo aqui con ese nombre. Para comprobar que es el mismo:"
	@echo "     shasum -a 256 $(ROM)"
	@echo "     $(SHA)"
	@echo "=================================================================="
	@false

comprueba: $(ROM)
	@echo "$(SHA)  $(ROM)" | shasum -a 256 -c -

# El trazado sigue el flujo desde los puntos de entrada. Los que no se pueden
# deducir estaticamente -ganchos de interrupcion, destinos de saltos
# indirectos- estan declarados en el .entries, cada uno con su justificacion.
$(WORK)/hypersports1.trace.json: $(ROM) $(SRC)/hypersports1.entries $(SRC)/hypersports1.nocode
	@mkdir -p $(WORK)
	python3 tools/z80trace.py $(ROM) $(ORG) $(SRC)/hypersports1.entries \
	        $(WORK)/hypersports1 $(SRC)/hypersports1.nocode

trace: $(WORK)/hypersports1.trace.json

listado: $(WORK)/hypersports1.trace.json $(SRC)/hypersports1.notes
	python3 tools/mkasm.py $(ROM) $(ORG) $(WORK)/hypersports1.trace.json \
	        $(SRC)/hypersports1.notes work/msx.sym $(SRC)/hypersports1.asm "$(TITULO)"

# La prueba que decide si el desensamblado es fiable.
verify: $(SRC)/hypersports1.asm $(ROM)
	@sh tools/verify_build.sh $(SRC)/hypersports1.asm $(ROM) $(ORG)

# Lo que el reensamblado NO puede cazar: que unos datos se esten leyendo como
# codigo. El binario sale identico igual, porque los bytes no cambian; lo unico
# que cambia es lo que decimos de ellos.
sanity: $(WORK)/hypersports1.trace.json
	@echo "=================================================================="
	@echo " ningun byte declarado como datos puede salir como codigo"
	@echo "=================================================================="
	@python3 tools/check_trace.py $(WORK)/hypersports1.trace.json $(SRC)/hypersports1.nocode
	@python3 tools/check_datos_como_codigo.py $(WORK) $(SRC)
	@echo "=================================================================="
	@echo " ningun punto de entrada puede caer dentro de una zona de datos"
	@echo "=================================================================="
	@python3 tools/check_entradas.py $(SRC)/hypersports1.entries $(SRC)/hypersports1.notes \
	        $(SRC)/hypersports1.nocode
	@echo "=================================================================="
	@echo " ni un byte del cartucho sin asignar"
	@echo "=================================================================="
	@python3 tools/presupuesto.py $(WORK) $(SRC)

densidad:
	@python3 tools/densidad.py $(SRC)/hypersports1.asm

test:
	@echo "=================================================================="
	@echo " Tests"
	@echo "=================================================================="
	@python3 -m unittest discover -s tests -v

# Dibuja los bloques de datos graficos declarados en el .notes, para MIRARLOS.
imagenes: $(ROM)
	@mkdir -p work/gfx
	python3 tools/dibuja.py $(ROM) $(ORG) $(SRC)/hypersports1.notes work/gfx

# LAS ESCENAS DE LAS PRUEBAS
#
# Los dibujos salen de la ROM; el mapa de casillas y los sprites, de la VRAM
# volcada en src/vram, porque la pantalla de una prueba no esta guardada en
# ningun sitio del cartucho: la compone el motor mientras corre. `escenas` las
# dibuja y de paso COTEJA la ROM contra esos volcados byte a byte.
escenas: $(ROM)
	python3 tools/escenas.py $(ROM) $(ORG) $(SRC)/hypersports1.notes 	        $(SRC)/vram docs/imagenes

# Que fotogramas del atleta usa cada prueba, cruzando el bloque con la medida.
posturas: $(ROM)
	@python3 tools/posturas.py $(ROM) $(ORG) $(SRC)/hypersports1.notes 	        $(WORK)/omsx/posturas.txt

# Vuelve a volcar la VRAM de las cuatro pruebas y la fuente de la BIOS. Necesita
# openMSX y la ROM; deja los ficheros en work/omsx/escenas, que hay que copiar a
# src/vram si se quieren cambiar los instantes.
vram: $(ROM)
	"$(OPENMSX)" -machine Philips_VG_8020 -cart $(ROM) -script tools/omsx_escenas.tcl
	"$(OPENMSX)" -machine Philips_VG_8020 -cart $(ROM) -script tools/omsx_posturas.tcl

# LA WEB
#
# Bilingue: el ingles en docs/ y el castellano en docs/es/. Las paginas se
# escriben en markdown y se convierten con md2html.py; la portada la monta
# make_web.py, que declara las cifras medidas de ESTE cartucho.
web: $(ROM)
	python3 tools/graficos.py $(ROM) $(ORG) $(SRC)/hypersports1.notes docs/imagenes
	python3 tools/figuras.py $(ROM) $(ORG) docs/imagenes
	python3 tools/escenas.py $(ROM) $(ORG) $(SRC)/hypersports1.notes $(SRC)/vram docs/imagenes
	python3 tools/md2html.py docs en
	python3 tools/md2html.py docs/es es
	python3 tools/make_web.py docs/imagenes docs/index.html en
	python3 tools/make_web.py docs/imagenes docs/es/index.html es
	python3 tools/check_enlaces.py docs

clean:
	rm -rf $(WORK)/hypersports1.trace.json $(WORK)/hypersports1.blocks

.PHONY: all comprueba trace listado verify sanity test densidad imagenes escenas posturas vram web clean
