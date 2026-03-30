Getting Started
===============

Prerequisites
-------------

- `Verilator <https://github.com/verilator/verilator>`_ must be installed.
  Follow the installation instructions on the Verilator repository if you have
  not set it up before.

Clone the Repository
--------------------

.. code-block:: bash

   git clone <repo-url> uriscv
   cd uriscv

Set Up the Environment
----------------------

Source the environment script to add ``scripts/`` to your PATH and enable tab
completion:

.. code-block:: bash

   source env.sh

To make this permanent, add it to your ``~/.bashrc``:

.. code-block:: bash

   echo "source $(pwd)/env.sh" >> ~/.bashrc
