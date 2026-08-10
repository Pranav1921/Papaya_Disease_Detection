import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from gradcam import get_gradcam_overlay


class GradCamTests(unittest.TestCase):
    def test_get_gradcam_overlay_returns_none_when_model_is_missing(self):
        self.assertIsNone(get_gradcam_overlay(None, None))


if __name__ == "__main__":
    unittest.main()
