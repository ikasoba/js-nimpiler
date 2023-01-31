# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest

import js_nimpiler

test "compile 1 + 2 * 3":
  check (1 + 2'jsn * 3'f64).compile == "1 + 2 * 3"

test "compile 1234[\"toString\"]()":
  check (1234'jsn["toString"]()).compile == "1234[\"toString\"]()"

test "compile (x) => x + 1234":
  check js((x) => jsi"x" + 1234).compile == "(x) => x + 1234"