from sys import argv

operator_id = argv[1]

operator_name = """\
SELECT operator_name from core_operator
WHERE operator_id='{}';""".format(operator_id)

core_parameters = """\
SELECT param_key, param_value FROM core_operator_params
WHERE operator_id='{}' and param_key like ('reportEndpoint%');
""".format(operator_id)

operator_reports = """\
SELECT param_value from core_operator_params
WHERE operator_id={} and param_key="reportList";
""".format(operator_id)

aggregated_name = """\
SELECT param_value from core_operator_params
WHERE operator_id={} and param_key="reportAggregatedName";
""".format(operator_id)

aggregated_operators = """\
SELECT param_value from core_operator_params
WHERE operator_id={} and param_key="reportAggregatedOperators";
""".format(operator_id)
