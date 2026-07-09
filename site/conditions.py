"""
Condition expression parsing and evaluation.

Conditions appear in layer metadata to make behaviour depend on variable
values at build time, eg in trigger rules and conflict mgmt, eg:

    when=IGconf_device_class in ['pi4', 'cm4', 'pi5', 'cm5']
    when=IGconf_hardening_apparmor == 'y'
    when=IGconf_device_user1pass != ''

The expression syntax is standard Python comparison syntax, parsed using
Python's own ast module. Operators and their semantics are precisely
defined by the Python language specification:

    https://docs.python.org/3/reference/expressions.html#comparisons

Supported comparison operators:  ==  !=  in  not in
Supported boolean operators:     and  or
Supported trait functions:       has()  not has()

Variable names in expressions are resolved from a plain dict[str, str]
passed in by the caller. The caller is responsible for building that dict
(typically from resolved layer variables with os.environ overrides applied).
"""

import ast
from typing import Dict, List, NamedTuple, Optional


class SyntaxExample(NamedTuple):
    operator: str   # operator or keyword, e.g. '==' or 'and'
    example: str    # complete when= form ready for use in layer metadata


# One entry per supported operator, and bare for documentation purposes.
SYNTAX_EXAMPLES: List[SyntaxExample] = [
    SyntaxExample("==",     "IGconf_device_class == 'pi5'"),
    SyntaxExample("!=",     "IGconf_device_user1pass != ''"),
    SyntaxExample("in",     "IGconf_device_class in ['pi4', 'cm4', 'pi5', 'cm5']"),
    SyntaxExample("not in", "IGconf_device_class not in ['zero2w']"),
    SyntaxExample("and",     "IGconf_a == 'x' and IGconf_b == 'y'"),
    SyntaxExample("or",      "IGconf_a == 'x' or IGconf_b == 'y'"),
    SyntaxExample("has",     "has('hw:bluetooth')"),
    SyntaxExample("not has", "not has('hw:bluetooth')"),
]


def syntax_examples() -> List[SyntaxExample]:
    """Return the list of supported condition syntax examples.
    Intended for docgen / help text renderers.
    """
    return SYNTAX_EXAMPLES


def validate(condition: str) -> None:
    """
    Parse and validate a condition expression string.
    """
    try:
        tree = ast.parse(condition, mode='eval')
    except SyntaxError as e:
        raise ValueError(f"Invalid condition '{condition}': {e}") from e
    if not isinstance(tree.body, (ast.Compare, ast.BoolOp, ast.Call, ast.UnaryOp)):
        raise ValueError(
            f"Invalid condition '{condition}': must be a comparison, boolean, or trait expression"
            f" — e.g. IGconf_x == 'value', IGconf_x in ['a', 'b'], has('hw:bluetooth')"
        )
    _check_node(tree.body, condition)


def evaluate(condition: str, variables: Dict[str, str],
             provider_index: Optional[Dict[str, str]] = None) -> bool:
    """
    Evaluate a condition expression against a variable dict.
    Parses the expression and walks the AST, resolving variable names against
    the provided dict. Assumes validate() has already been called.

    provider_index must be supplied when the condition contains has() calls.
    """
    tree = ast.parse(condition, mode='eval')
    return bool(_eval_node(tree.body, variables, condition, provider_index))


# -----------------------------------------------------------------------------
# Internal helpers
# -----------------------------------------------------------------------------
# Both helpers walk the AST produced by ast.parse(). Only the node types that
# correspond to the supported expression forms are handled, anything else
# raises an error so it's easy to report what a condition can/cannot do.


def _check_node(node, condition: str) -> None:
    """
    Recursively walk an AST node and raise ValueError for any node type that
    is outside the supported subset.
    """
    if isinstance(node, ast.Compare):
        # Chained comparisons (e.g. a < b < c) parse as a single Compare node
        # with multiple ops. We do not support them - one comparison per expression.
        if len(node.ops) != 1:
            raise ValueError(
                f"Chained comparisons are not supported in '{condition}'"
            )
        if not isinstance(node.ops[0], (ast.Eq, ast.NotEq, ast.In, ast.NotIn)):
            raise ValueError(
                f"Unsupported operator '{type(node.ops[0]).__name__}' in '{condition}'"
                f" — supported operators are ==, !=, in, not in"
            )
        _check_node(node.left, condition)
        _check_node(node.comparators[0], condition)

    elif isinstance(node, ast.BoolOp):
        # BoolOp covers 'and' and 'or'. Both are supported for compound conditions
        # such as: IGconf_a == 'x' and IGconf_b == 'y'
        for value in node.values:
            _check_node(value, condition)

    elif isinstance(node, ast.Name):
        # A bare name is a variable reference, looked up in the variables dict
        # at evaluation time. No validation of the name itself happens here -
        # unknown names are caught by evaluate().
        pass

    elif isinstance(node, ast.Constant):
        # Only string constants are permitted. An unquoted value like pi5 would
        # be parsed as a Name node (variable lookup), not a Constant. If someone
        # writes a numeric or boolean literal it is almost certainly a mistake,
        # so reject it with a clear message.
        if not isinstance(node.value, str):
            raise ValueError(
                f"Non-string constant {node.value!r} in '{condition}'"
                f" — comparison values must be quoted strings, e.g. 'pi5'"
            )

    elif isinstance(node, (ast.List, ast.Tuple)):
        # Lists and tuples are the right-hand side of 'in' / 'not in', e.g.
        # IGconf_device_class in ['pi4', 'cm4', 'pi5', 'cm5'].
        # Each element must itself be a valid (typically Constant) node.
        for elt in node.elts:
            _check_node(elt, condition)

    elif isinstance(node, ast.UnaryOp):
        # Only 'not has(...)' is supported. 'not' applied to a variable name
        # (e.g. 'not IGconf_x') would silently invert the string's truthiness,
        # which is never what a layer author intends.
        if not isinstance(node.op, ast.Not):
            raise ValueError(
                f"Unsupported unary operator in '{condition}' — only 'not' is supported"
            )
        if not isinstance(node.operand, ast.Call):
            raise ValueError(
                f"'not' can only negate has() in '{condition}'"
                f" — use != '' to test for a non-empty variable"
            )
        _check_node(node.operand, condition)

    elif isinstance(node, ast.Call):
        # Only has('token') is permitted — no other function calls.
        if not (isinstance(node.func, ast.Name) and node.func.id == 'has'):
            raise ValueError(
                f"Unsupported function call in '{condition}' — only has() is permitted"
            )
        if len(node.args) != 1 or node.keywords:
            raise ValueError(
                f"has() requires exactly one string argument in '{condition}'"
            )
        if not isinstance(node.args[0], ast.Constant) or not isinstance(node.args[0].value, str):
            raise ValueError(
                f"has() argument must be a quoted string in '{condition}'"
            )

    else:
        raise ValueError(
            f"Unsupported expression '{type(node).__name__}' in '{condition}'"
        )


def _eval_node(node, variables: Dict[str, str], condition: str,
               provider_index: Optional[Dict[str, str]] = None):
    """
    Recursively evaluate an AST node and return a Python value.

    Compare nodes return bool. Name and Constant nodes return str.
    List and Tuple nodes return list[str] for use with 'in' / 'not in'.
    Call nodes (has()) return bool. UnaryOp(Not) inverts its operand.
    """
    if isinstance(node, ast.Compare):
        left = _eval_node(node.left, variables, condition, provider_index)
        right = _eval_node(node.comparators[0], variables, condition, provider_index)
        op = node.ops[0]
        if isinstance(op, ast.Eq):    return left == right
        if isinstance(op, ast.NotEq): return left != right
        if isinstance(op, ast.In):    return left in right
        if isinstance(op, ast.NotIn): return left not in right

    if isinstance(node, ast.BoolOp):
        # Use all() / any() so that short-circuit eval is preserved
        if isinstance(node.op, ast.And):
            return all(_eval_node(v, variables, condition, provider_index) for v in node.values)
        return any(_eval_node(v, variables, condition, provider_index) for v in node.values)

    if isinstance(node, ast.UnaryOp):
        return not _eval_node(node.operand, variables, condition, provider_index)

    if isinstance(node, ast.Call):
        token = node.args[0].value
        if provider_index is None:
            raise ValueError(
                f"has() used in '{condition}' but no provider index is available"
            )
        return token in provider_index

    if isinstance(node, ast.Name):
        if node.id not in variables:
            raise ValueError(
                f"Unknown variable '{node.id}' in condition '{condition}'"
            )
        return variables[node.id]

    if isinstance(node, ast.Constant):
        return node.value

    if isinstance(node, (ast.List, ast.Tuple)):
        return [_eval_node(e, variables, condition, provider_index) for e in node.elts]

    raise ValueError(
        f"Unsupported node '{type(node).__name__}' in condition '{condition}'"
    )
