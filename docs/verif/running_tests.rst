Running Tests
=============

Single Test
-----------

.. code-block:: bash

   run <testname>

For example:

.. code-block:: bash

   run test_cpu_bringup_basic

To generate a waveform (``waveform.vcd``), pass ``--trace``:

.. code-block:: bash

   run --trace test_cpu_bringup_basic

Simulation outputs and the waveform are written to ``rundir/<testname>/``.

With tab completion active (from ``env.sh``), pressing ``<Tab>`` after ``run``
will suggest available test names.

Regressions
-----------

Regressions are named lists of tests stored as ``<regressname>.list`` files
under ``tb/``. Any name beginning with ``regress_`` is treated as a regression
instead of a single test.

.. code-block:: bash

   run <regressname>

For example:

.. code-block:: bash

   run regress_cpu_bringup

By default, regressions run **2 tests in parallel**. Use ``-j N`` to control
parallelism:

.. code-block:: bash

   run regress_cpu_bringup -j 4   # run 4 tests in parallel
   run regress_cpu_bringup -j 1   # run sequentially

Each test's output is captured to ``rundir/<regressname>/<testname>/run.log``.
A summary is printed at the end::

     PASS   test_cpu_bringup_arithmetic
     PASS   test_cpu_bringup_branch
     FAIL   test_cpu_bringup_mem_hazard  (see rundir/regress_cpu_bringup/test_cpu_bringup_mem_hazard/run.log)
     PASS   test_cpu_bringup_memory

Creating a Regression List
--------------------------

Create a ``.list`` file under ``tb/`` with one test name per line. Lines
starting with ``#`` are treated as comments::

   # tb/cpu/bringup/regressions/regress_my_suite.list
   test_cpu_bringup_arithmetic
   test_cpu_bringup_branch
   test_cpu_bringup_memory

Run it with:

.. code-block:: bash

   run regress_my_suite
