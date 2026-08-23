import importlib.util
import sys
from pathlib import Path

import pytest


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SRC_DIR = PROJECT_ROOT / "src"
API_PATH = PROJECT_ROOT / "app" / "api_server.py"

if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))


@pytest.fixture(scope="session")
def api_server():
    """Load the file-based API module once for the whole test session."""
    module_name = "papaya_test_api_server"
    spec = importlib.util.spec_from_file_location(module_name, API_PATH)
    module = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = module
    spec.loader.exec_module(module)
    return module
