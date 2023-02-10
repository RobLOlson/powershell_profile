"""python interpreter profile
Point your $PYTHONSTARTUP environment variable at this file."""

import os
from functools import reduce

import rich.traceback
from rich import inspect, pretty

pretty.install()

rich.traceback.install()

dir = inspect

os.environ["PYTHONBREAKPOINT"] = "pdbr.set_trace"


def compose(*functions):
    """Compose multiple unary functions.  E.g., compose(plus_2, times_2, minus_2)"""
    return reduce(lambda f, g: lambda x: g(f(x)), functions)


def transpose(matrix):
    """If matrix is m x n, return its n x m transpose."""
    return list(zip(*matrix))


try:
    from ptpython.repl import embed
except ImportError:
    print("ptpython is not available: falling back to standard prompt")
else:
    embed(globals(), locals())
