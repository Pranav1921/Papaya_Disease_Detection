import sys
import unittest
from pathlib import Path
from unittest.mock import patch

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from gradcam import get_gradcam_overlay


class GradCamTests(unittest.TestCase):
    def test_get_gradcam_overlay_returns_none_when_model_is_missing(self):
        self.assertIsNone(get_gradcam_overlay(None, None))

    def test_get_gradcam_overlay_returns_none_when_image_is_missing(self):
        self.assertIsNone(get_gradcam_overlay(object(), None))

    def test_get_gradcam_overlay_returns_none_when_tensorflow_is_missing(self):
        with patch.dict(sys.modules, {"tensorflow": None}):
            self.assertIsNone(get_gradcam_overlay(object(), np.zeros((1, 2, 2, 3))))


if __name__ == "__main__":
    unittest.main()
