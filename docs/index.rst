u-RISC-V Documentation
======================

u-RISC-V (micro-RISC-V) is an open source RISC-V CPU project that is developed
and tested using Verilator, bypassing commonly licensed EDA tools.

.. toctree::
   :maxdepth: 3
   :caption: Project Setup

   getting_started

.. toctree::
   :maxdepth: 3
   :caption: Design

   design/architecture
   design/design_requirements
   design/performance_benchmark

.. toctree::
   :maxdepth: 3
   :caption: Verification

   verif/running_tests
   verif/vreqs


.. toctree::
   :maxdepth: 2
   :caption: Glossary

   glossary



Project Structure
-------------------

::

   hdl/
   ├── chiplevel/       Top-level chip integration and defines
   ├── common/          Reusable building blocks (DFFs, SRAM, memory)
   ├── cpu/
   │   ├── components/  Functional units (ALU, hazard detection, etc.)
   │   ├── datapath/    Pipeline stage modules
   │   ├── reg/         Register file
   │   └── top/         CPU top-level wrapper
   └── llc/             Last-level cache (planned)

   tb/
   ├── cpu/
   │   ├── bringup/     Basic CPU integration tests
   │   └── asm/         Assembly-level tests
   ├── rv_uvc/          RISC-V UVM verification components
   └── ...

   scripts/             Build, run, and completion scripts