"""python interpreter profile
Point your $PYTHONSTARTUP environment variable at this file."""

import os
import pdb
import sys
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


def configure(repl):
    """
    Configuration method. This is called during the start-up of ptpython.
    :param repl: `PythonRepl` instance.
    """
    # Show function signature (bool).
    repl.show_signature = True

    # Show docstring (bool).
    repl.show_docstring = True

    # Fuzzy and dictionary completion.
    repl.enable_fuzzy_completion = True

    # Enable auto suggestions. (Pressing right arrow will complete the input,
    # based on the history.)
    repl.enable_auto_suggest = True

    repl.paste_mode = True

    repl.highlight_matching_parenthesis = True

    # Mouse support.
    repl.enable_mouse_support = True

    repl.enable_dictionary_completion = True

    # Enable the modal cursor (when using Vi mode). Other options are 'Block', 'Underline',  'Beam',  'Blink under', 'Blink block', and 'Blink beam'
    repl.cursor_shape_config = "Beam"

    # Enable auto suggestions. (Pressing right arrow will complete the input,
    # based on the history.)
    repl.enable_auto_suggest = True

    # History Search.
    # When True, going back in history will filter the history on the records
    # starting with the current input. (Like readline.)
    # Note: When enable, please disable the `complete_while_typing` option.
    #       otherwise, when there is a completion available, the arrows will
    #       browse through the available completions instead of the history.
    repl.enable_history_search = True
    repl.complete_while_typing = False

    # Ask for confirmation on exit.
    repl.confirm_exit = False

    # Enable input validation. (Don't try to execute when the input contains
    # syntax errors.)
    repl.enable_input_validation = True

    # Syntax.
    repl.enable_syntax_highlighting = True


try:
    from ptpython.repl import embed
except ImportError:
    print("ptpython is not available: falling back to standard prompt")
else:
    sys.exit(embed(globals(), locals(), configure=configure))
