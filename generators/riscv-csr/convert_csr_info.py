#!/usr/bin/env python

from __future__ import print_function
from builtins import hex
from builtins import range
import math
import sys
import tokenize

namelist = []
match = {}
mask = {}
pseudos = {}
arguments = {}

arglut = {}
arglut['rd'] = (11,7)
arglut['rs1'] = (19,15)
arglut['rs2'] = (24,20)
arglut['rs3'] = (31,27)
arglut['aqrl'] = (26,25)
arglut['fm'] = (31,28)
arglut['pred'] = (27,24)
arglut['succ'] = (23,20)
arglut['rm'] = (14,12)
arglut['funct3'] = (14,12)
arglut['imm20'] = (31,12)
arglut['jimm20'] = (31,12)
arglut['imm12'] = (31,20)
arglut['imm12hi'] = (31,25)
arglut['bimm12hi'] = (31,25)
arglut['imm12lo'] = (11,7)
arglut['bimm12lo'] = (11,7)
arglut['zimm'] = (19,15)
arglut['shamt'] = (25,20)
arglut['shamtw'] = (24,20)

# for vectors
arglut['vd'] = (11,7)
arglut['vs3'] = (11,7)
arglut['vs1'] = (19,15)
arglut['vs2'] = (24,20)
arglut['vm'] = (25,25)
arglut['amoop'] = (31,27)
arglut['nf'] = (31,29)
arglut['simm5'] = (19,15)
arglut['zimm11'] = (30,20)


causes = [
  (0x00, 'misaligned fetch'),
  (0x01, 'fetch access'),
  (0x02, 'illegal instruction'),
  (0x03, 'breakpoint'),
  (0x04, 'misaligned load'),
  (0x05, 'load access'),
  (0x06, 'misaligned store'),
  (0x07, 'store access'),
  (0x08, 'user_ecall'),
  (0x09, 'supervisor_ecall'),
  (0x0A, 'hypervisor_ecall'),
  (0x0B, 'machine_ecall'),
  (0x0C, 'fetch page fault'),
  (0x0D, 'load page fault'),
  (0x0F, 'store page fault'),
]

csrs = [
  # Standard User R/W
  (0x001, 'fflags'),
  (0x002, 'frm'),
  (0x003, 'fcsr'),
  (0x000, 'ustatus'),
  (0x004, 'uie'),
  (0x005, 'utvec'),
  (0x008, 'vstart'),
  (0x009, 'vxsat'),
  (0x00A, 'vxrm'),
  (0x040, 'uscratch'),
  (0x041, 'uepc'),
  (0x042, 'ucause'),
  (0x043, 'utval'),
  (0x044, 'uip'),

  # Standard User RO
  (0xC00, 'cycle'),
  (0xC01, 'time'),
  (0xC02, 'instret'),
  (0xC03, 'hpmcounter3'),
  (0xC04, 'hpmcounter4'),
  (0xC05, 'hpmcounter5'),
  (0xC06, 'hpmcounter6'),
  (0xC07, 'hpmcounter7'),
  (0xC08, 'hpmcounter8'),
  (0xC09, 'hpmcounter9'),
  (0xC0A, 'hpmcounter10'),
  (0xC0B, 'hpmcounter11'),
  (0xC0C, 'hpmcounter12'),
  (0xC0D, 'hpmcounter13'),
  (0xC0E, 'hpmcounter14'),
  (0xC0F, 'hpmcounter15'),
  (0xC10, 'hpmcounter16'),
  (0xC11, 'hpmcounter17'),
  (0xC12, 'hpmcounter18'),
  (0xC13, 'hpmcounter19'),
  (0xC14, 'hpmcounter20'),
  (0xC15, 'hpmcounter21'),
  (0xC16, 'hpmcounter22'),
  (0xC17, 'hpmcounter23'),
  (0xC18, 'hpmcounter24'),
  (0xC19, 'hpmcounter25'),
  (0xC1A, 'hpmcounter26'),
  (0xC1B, 'hpmcounter27'),
  (0xC1C, 'hpmcounter28'),
  (0xC1D, 'hpmcounter29'),
  (0xC1E, 'hpmcounter30'),
  (0xC1F, 'hpmcounter31'),
  (0xC20, 'vl'),
  (0xC21, 'vtype'),

  # Standard Supervisor R/W
  (0x100, 'sstatus'),
  (0x104, 'sie'),
  (0x105, 'stvec'),
  (0x106, 'scounteren'),
  (0x140, 'sscratch'),
  (0x141, 'sepc'),
  (0x142, 'scause'),
  (0x143, 'stval'),
  (0x144, 'sip'),
  (0x180, 'satp'),

  # Standard Hypervisor R/w
  (0x200, 'bsstatus'),
  (0x204, 'bsie'),
  (0x205, 'bstvec'),
  (0x240, 'bsscratch'),
  (0x241, 'bsepc'),
  (0x242, 'bscause'),
  (0x243, 'bstval'),
  (0x244, 'bsip'),
  (0x280, 'bsatp'),
  (0xA00, 'hstatus'),
  (0xA02, 'hedeleg'),
  (0xA03, 'hideleg'),
  (0xA80, 'hgatp'),

  # Tentative CSR assignment for CLIC
  (0x007, 'utvt'),
  (0x045, 'unxti'),
  (0x046, 'uintstatus'),
  (0x048, 'uscratchcsw'),
  (0x049, 'uscratchcswl'),
  (0x107, 'stvt'),
  (0x145, 'snxti'),
  (0x146, 'sintstatus'),
  (0x148, 'sscratchcsw'),
  (0x149, 'sscratchcswl'),
  (0x307, 'mtvt'),
  (0x345, 'mnxti'),
  (0x346, 'mintstatus'),
  (0x348, 'mscratchcsw'),
  (0x349, 'mscratchcswl'),

  # Standard Machine R/W
  (0x300, 'mstatus'),
  (0x301, 'misa'),
  (0x302, 'medeleg'),
  (0x303, 'mideleg'),
  (0x304, 'mie'),
  (0x305, 'mtvec'),
  (0x306, 'mcounteren'),
  (0x340, 'mscratch'),
  (0x341, 'mepc'),
  (0x342, 'mcause'),
  (0x343, 'mtval'),
  (0x344, 'mip'),
  (0x3a0, 'pmpcfg0'),
  (0x3a1, 'pmpcfg1'),
  (0x3a2, 'pmpcfg2'),
  (0x3a3, 'pmpcfg3'),
  (0x3b0, 'pmpaddr0'),
  (0x3b1, 'pmpaddr1'),
  (0x3b2, 'pmpaddr2'),
  (0x3b3, 'pmpaddr3'),
  (0x3b4, 'pmpaddr4'),
  (0x3b5, 'pmpaddr5'),
  (0x3b6, 'pmpaddr6'),
  (0x3b7, 'pmpaddr7'),
  (0x3b8, 'pmpaddr8'),
  (0x3b9, 'pmpaddr9'),
  (0x3ba, 'pmpaddr10'),
  (0x3bb, 'pmpaddr11'),
  (0x3bc, 'pmpaddr12'),
  (0x3bd, 'pmpaddr13'),
  (0x3be, 'pmpaddr14'),
  (0x3bf, 'pmpaddr15'),
  (0x7a0, 'tselect'),
  (0x7a1, 'tdata1'),
  (0x7a2, 'tdata2'),
  (0x7a3, 'tdata3'),
  (0x7b0, 'dcsr'),
  (0x7b1, 'dpc'),
  (0x7b2, 'dscratch'),
  (0xB00, 'mcycle'),
  (0xB02, 'minstret'),
  (0xB03, 'mhpmcounter3'),
  (0xB04, 'mhpmcounter4'),
  (0xB05, 'mhpmcounter5'),
  (0xB06, 'mhpmcounter6'),
  (0xB07, 'mhpmcounter7'),
  (0xB08, 'mhpmcounter8'),
  (0xB09, 'mhpmcounter9'),
  (0xB0A, 'mhpmcounter10'),
  (0xB0B, 'mhpmcounter11'),
  (0xB0C, 'mhpmcounter12'),
  (0xB0D, 'mhpmcounter13'),
  (0xB0E, 'mhpmcounter14'),
  (0xB0F, 'mhpmcounter15'),
  (0xB10, 'mhpmcounter16'),
  (0xB11, 'mhpmcounter17'),
  (0xB12, 'mhpmcounter18'),
  (0xB13, 'mhpmcounter19'),
  (0xB14, 'mhpmcounter20'),
  (0xB15, 'mhpmcounter21'),
  (0xB16, 'mhpmcounter22'),
  (0xB17, 'mhpmcounter23'),
  (0xB18, 'mhpmcounter24'),
  (0xB19, 'mhpmcounter25'),
  (0xB1A, 'mhpmcounter26'),
  (0xB1B, 'mhpmcounter27'),
  (0xB1C, 'mhpmcounter28'),
  (0xB1D, 'mhpmcounter29'),
  (0xB1E, 'mhpmcounter30'),
  (0xB1F, 'mhpmcounter31'),
  (0x323, 'mhpmevent3'),
  (0x324, 'mhpmevent4'),
  (0x325, 'mhpmevent5'),
  (0x326, 'mhpmevent6'),
  (0x327, 'mhpmevent7'),
  (0x328, 'mhpmevent8'),
  (0x329, 'mhpmevent9'),
  (0x32A, 'mhpmevent10'),
  (0x32B, 'mhpmevent11'),
  (0x32C, 'mhpmevent12'),
  (0x32D, 'mhpmevent13'),
  (0x32E, 'mhpmevent14'),
  (0x32F, 'mhpmevent15'),
  (0x330, 'mhpmevent16'),
  (0x331, 'mhpmevent17'),
  (0x332, 'mhpmevent18'),
  (0x333, 'mhpmevent19'),
  (0x334, 'mhpmevent20'),
  (0x335, 'mhpmevent21'),
  (0x336, 'mhpmevent22'),
  (0x337, 'mhpmevent23'),
  (0x338, 'mhpmevent24'),
  (0x339, 'mhpmevent25'),
  (0x33A, 'mhpmevent26'),
  (0x33B, 'mhpmevent27'),
  (0x33C, 'mhpmevent28'),
  (0x33D, 'mhpmevent29'),
  (0x33E, 'mhpmevent30'),
  (0x33F, 'mhpmevent31'),

  # Standard Machine RO
  (0xF11, 'mvendorid'),
  (0xF12, 'marchid'),
  (0xF13, 'mimpid'),
  (0xF14, 'mhartid'),
]

csrs32 = [
  # Standard User RO
  (0xC80, 'cycleh'),
  (0xC81, 'timeh'),
  (0xC82, 'instreth'),
  (0xC83, 'hpmcounter3h'),
  (0xC84, 'hpmcounter4h'),
  (0xC85, 'hpmcounter5h'),
  (0xC86, 'hpmcounter6h'),
  (0xC87, 'hpmcounter7h'),
  (0xC88, 'hpmcounter8h'),
  (0xC89, 'hpmcounter9h'),
  (0xC8A, 'hpmcounter10h'),
  (0xC8B, 'hpmcounter11h'),
  (0xC8C, 'hpmcounter12h'),
  (0xC8D, 'hpmcounter13h'),
  (0xC8E, 'hpmcounter14h'),
  (0xC8F, 'hpmcounter15h'),
  (0xC90, 'hpmcounter16h'),
  (0xC91, 'hpmcounter17h'),
  (0xC92, 'hpmcounter18h'),
  (0xC93, 'hpmcounter19h'),
  (0xC94, 'hpmcounter20h'),
  (0xC95, 'hpmcounter21h'),
  (0xC96, 'hpmcounter22h'),
  (0xC97, 'hpmcounter23h'),
  (0xC98, 'hpmcounter24h'),
  (0xC99, 'hpmcounter25h'),
  (0xC9A, 'hpmcounter26h'),
  (0xC9B, 'hpmcounter27h'),
  (0xC9C, 'hpmcounter28h'),
  (0xC9D, 'hpmcounter29h'),
  (0xC9E, 'hpmcounter30h'),
  (0xC9F, 'hpmcounter31h'),

  # Standard Machine RW
  (0xB80, 'mcycleh'),
  (0xB82, 'minstreth'),
  (0xB83, 'mhpmcounter3h'),
  (0xB84, 'mhpmcounter4h'),
  (0xB85, 'mhpmcounter5h'),
  (0xB86, 'mhpmcounter6h'),
  (0xB87, 'mhpmcounter7h'),
  (0xB88, 'mhpmcounter8h'),
  (0xB89, 'mhpmcounter9h'),
  (0xB8A, 'mhpmcounter10h'),
  (0xB8B, 'mhpmcounter11h'),
  (0xB8C, 'mhpmcounter12h'),
  (0xB8D, 'mhpmcounter13h'),
  (0xB8E, 'mhpmcounter14h'),
  (0xB8F, 'mhpmcounter15h'),
  (0xB90, 'mhpmcounter16h'),
  (0xB91, 'mhpmcounter17h'),
  (0xB92, 'mhpmcounter18h'),
  (0xB93, 'mhpmcounter19h'),
  (0xB94, 'mhpmcounter20h'),
  (0xB95, 'mhpmcounter21h'),
  (0xB96, 'mhpmcounter22h'),
  (0xB97, 'mhpmcounter23h'),
  (0xB98, 'mhpmcounter24h'),
  (0xB99, 'mhpmcounter25h'),
  (0xB9A, 'mhpmcounter26h'),
  (0xB9B, 'mhpmcounter27h'),
  (0xB9C, 'mhpmcounter28h'),
  (0xB9D, 'mhpmcounter29h'),
  (0xB9E, 'mhpmcounter30h'),
  (0xB9F, 'mhpmcounter31h'),
]

opcode_base = 0
opcode_size = 7
funct_base = 12
funct_size = 3

