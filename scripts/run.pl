#!/usr/bin/env perl
# run.pl - build and run a simulation test with Verilator
#
# Usage: scripts/run.pl [options] <testname>
# Example: scripts/run.pl test_cpu_bringup
#          scripts/run.pl --trace test_cpu_bringup_basic
#
# The script will:
#   1. Find <testname>.svh (new style) or <testname>.sv (legacy) under tb/
#   2. For .svh tests: read tb/cpu/bringup/template/bringup_wrapper.sv.tmpl,
#      substitute %%TESTNAME%%, and write a generated top module to rundir/
#   3. Resolve the source filelist (.f): per-test if present, else hdl/cpu/top/cpu.f
#   4. Expand path variables in the filelist
#   5. Compile with Verilator into rundir/<testname>/work/
#   6. Run the simulation (outputs, waveform.vcd land in rundir/<testname>/)

use strict;
use warnings;
use File::Find   ();
use File::Basename qw(dirname basename);
use File::Path   qw(make_path);
use Cwd          qw(abs_path getcwd);

# ---------------------------------------------------------------------------
# Locate repo root (one level up from this script)
# ---------------------------------------------------------------------------
my $script_dir = dirname(abs_path($0));
my $repo_root  = dirname($script_dir);

use Getopt::Long qw(GetOptions);

my $opt_trace = 0;
GetOptions('trace' => \$opt_trace) or die "Usage: $0 [--trace] <testname>\n";
die "Usage: $0 [--trace] <testname>\n" unless @ARGV == 1;
my $testname = $ARGV[0];

# ---------------------------------------------------------------------------
# Find the testbench file under tb/ (.svh new style, .sv legacy)
# ---------------------------------------------------------------------------
my ($tb_file, $test_style);
File::Find::find(sub {
    if ($_ eq "${testname}.svh" && !defined $tb_file) {
        $tb_file    = $File::Find::name;
        $test_style = 'svh';
    } elsif ($_ eq "${testname}.sv" && !defined $tb_file) {
        $tb_file    = $File::Find::name;
        $test_style = 'sv';
    }
}, "$repo_root/tb");

die "ERROR: could not find '${testname}.svh' or '${testname}.sv' under $repo_root/tb\n"
    unless defined $tb_file;

print "testbench : $tb_file  ($test_style)\n";

# ---------------------------------------------------------------------------
# Prepare output directories (needed before generating wrapper)
# ---------------------------------------------------------------------------
my $run_dir  = "$repo_root/rundir/$testname";
my $work_dir = "$run_dir/work" . ($opt_trace ? "_trace" : "");
make_path($work_dir);

# ---------------------------------------------------------------------------
# For .svh tests: generate the thin module wrapper from the template.
# For .sv tests:  use the file as-is (legacy path).
# ---------------------------------------------------------------------------
my ($verilator_top, @include_dirs);

if ($test_style eq 'svh') {
    my $tests_dir   = dirname($tb_file);                # .../tb/cpu/bringup/tests
    my $bringup_dir = dirname($tests_dir);              # .../tb/cpu/bringup
    my $env_dir     = "$bringup_dir/env";
    my $tmpl_file   = "$bringup_dir/template/bringup_wrapper.sv.tmpl";

    -d $env_dir   or die "ERROR: env dir not found: $env_dir\n";
    -f $tmpl_file or die "ERROR: wrapper template not found: $tmpl_file\n";

    my $wrapper = "$run_dir/${testname}.sv";
    open my $tmpl, '<', $tmpl_file or die "Cannot read $tmpl_file: $!\n";
    open my $wout, '>', $wrapper   or die "Cannot write $wrapper: $!\n";
    while (my $line = <$tmpl>) {
        $line =~ s/%%TESTNAME%%/$testname/g;
        print $wout $line;
    }
    close $tmpl;
    close $wout;
    print "generated : $wrapper\n";

    $verilator_top = $wrapper;
    @include_dirs  = ($env_dir, $tests_dir);
} else {
    my $tb_dir     = dirname($tb_file);
    $verilator_top = $tb_file;
    @include_dirs  = ($tb_dir);
}

# ---------------------------------------------------------------------------
# Resolve the filelist (.f)
# Convention: a <testname>.f next to the testbench takes priority;
#             otherwise fall back to hdl/cpu/top/cpu.f
# ---------------------------------------------------------------------------
my $tb_dir_for_f = dirname($tb_file);
my $per_test_f   = "$tb_dir_for_f/${testname}.f";
my $default_f    = "$repo_root/hdl/cpu/top/cpu.f";

my $src_f;
if (-f $per_test_f) {
    $src_f = $per_test_f;
    print "filelist  : $src_f  (per-test)\n";
} elsif (-f $default_f) {
    $src_f = $default_f;
    print "filelist  : $src_f  (default)\n";
} else {
    die "ERROR: no filelist found for '$testname'.\n"
      . "  Looked for: $per_test_f\n"
      . "  Fallback  : $default_f\n";
}

# ---------------------------------------------------------------------------
# Expand path variables in the filelist and write to run_dir
# ---------------------------------------------------------------------------
my %vars = (
    CPU_DIR      => "$repo_root/hdl/cpu",
    COMMON_DIR   => "$repo_root/hdl/common",
    CHIPLEVEL_DIR => "$repo_root/hdl/chiplevel",
);

my $expanded_f = "$run_dir/expanded.f";
open my $in,  '<', $src_f      or die "Cannot read $src_f: $!\n";
open my $out, '>', $expanded_f or die "Cannot write $expanded_f: $!\n";
while (my $line = <$in>) {
    $line =~ s/\$\{(\w+)\}/exists $vars{$1} ? $vars{$1} : die "Unknown variable \$$1 in filelist\n"/ge;
    print $out $line;
}
close $in;
close $out;

print "expanded  : $expanded_f\n";

# ---------------------------------------------------------------------------
# Compile with Verilator
# ---------------------------------------------------------------------------
my @compile = (
    'verilator',
    '--binary', '--sv', '-Wall', '--timing',
    '-Wno-TIMESCALEMOD',    # timescale only needed on tb top, not every submodule
    ($opt_trace ? '--trace' : ()),
    '--top-module', $testname,
    '--Mdir',       $work_dir,
    (map { "-I$_" } @include_dirs),
    '-f',           $expanded_f,
    $verilator_top,
);

print "\n--- compile ---\n";
print join(' ', @compile), "\n\n";
system(@compile) == 0
    or die "Verilator compilation failed (exit $?)\n";

# ---------------------------------------------------------------------------
# Run the simulation from run_dir so waveform.vcd lands there
# ---------------------------------------------------------------------------
my $sim_bin = "$work_dir/V${testname}";
-x $sim_bin or die "ERROR: compiled binary not found: $sim_bin\n";

print "\n--- simulate ---\n";
print "cwd: $run_dir\n";
print "$sim_bin\n\n";

chdir $run_dir or die "Cannot chdir to $run_dir: $!\n";
system($sim_bin) == 0
    or die "Simulation exited with non-zero status ($?)\n";

print "\nOutputs in $run_dir\n";
