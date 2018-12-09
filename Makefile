######################################################################
#
# DESCRIPTION: Verilator with GUI
#
# This calls the object directory makefile.  That allows the objects to
# be placed in the "current directory" which simplifies the Makefile.
#
# Copyright 2003-2018 by Wilson Snyder. This program is free software; you can
# redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License
# Version 2.0.
#
# Modifications by Icaro Dantas de Araujo Lima and Elmar Melcher at UFCG, 2018
#
######################################################################

# Check for sanity to avoid later confusion
ifneq ($(words $(CURDIR)),1)
 $(error Unsupported: GNU Make cannot build in directories containing spaces, build elsewhere: '$(CURDIR)')
endif

ifeq ($(findstring MINGW,$(shell uname)),MINGW)
  CFLTK=-I/usr/local/include
  LFLTK=-L/usr/local/lib -mwindows -lfltk_images -lfltk_png -lfltk_z -lfltk -lole32 -luuid -lcomctl32 -lws2_32
  FLTK=-CFLAGS "$(CFLTK)" -LDFLAGS "$(LFLTK)"
else
  LFLTK=-lfltk_images -lpng -lz -lfltk
  FLTK=-LDFLAGS "$(LFLTK)"
endif

HDL=top.sv inst_sim.sv memo_sim.sv
WARN=-Wno-CASEINCOMPLETE -Wno-WIDTH -Wno-COMBDLY
ifneq ("$(wildcard inst.s)","")
  INS=inst.objdump
else
  INS=inst.101
endif

######################################################################

.SUFFIXES: .objdump .s

# If $VERILATOR_ROOT isn't in the environment, we assume it is part of a
# package install, and verilator is in your path. Otherwise find the
# binary relative to $VERILATOR_ROOT (such as when inside the git sources).
ifeq ($(VERILATOR_ROOT),)
VERILATOR = verilator
else
export VERILATOR_ROOT
VERILATOR = $(VERILATOR_ROOT)/bin/verilator
endif

sim: $(INS)
	$(VERILATOR) $(WARN) -cc --exe +1800-2012ext+sv $(HDL) sim_main.cpp gui.cpp $(FLTK)
	$(MAKE) -j 2 -C obj_dir -f Vtop.mk
	obj_dir/Vtop

# from assembly to object dump
.s.objdump :
	riscv32-unknown-elf-gcc -nostdlib -nostartfiles -Tlink.ld $< && \
	riscv32-unknown-elf-objdump -s -j .text | egrep " [0-9a-f]{4} [0-9a-f]{8}" | cut -b7-41 > $@

maintainer-copy::
clean mostlyclean distclean maintainer-clean::
	-rm -rf obj_dir *.o *.log *.dmp *.vpd core a.out *.objdump *.sof *.fit.summary
