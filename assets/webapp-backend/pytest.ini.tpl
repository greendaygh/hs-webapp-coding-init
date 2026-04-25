[pytest]
minversion = 7.0
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts =
    -ra
    --strict-markers
    --strict-config
    --cov={{app_module}}
    --cov-report=term-missing
    --cov-report=xml
    --cov-fail-under={{coverage_threshold}}
markers =
    slow: marks tests as slow
    integration: integration tests requiring external services
    e2e: end-to-end tests
filterwarnings =
    error
    ignore::DeprecationWarning
