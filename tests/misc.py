import operator

OperatorMap = {
    "<": operator.lt,
    ">": operator.gt,
    "==": operator.eq,
    "!=": operator.ne,
    ">=": operator.ge,
    "<=": operator.le,
}

OperatorIterMap = {
    "<": [operator.lt, operator.le],
    ">": [operator.gt, operator.ge],
    "==": [operator.eq],
    "!=": [operator.ne],
    ">=": [operator.ge],
    "<=": [operator.le],
}
