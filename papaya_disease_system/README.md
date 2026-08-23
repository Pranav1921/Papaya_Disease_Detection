## Running the tests

From `papaya_disease_system`, activate the virtual environment:

```powershell
# Windows PowerShell
.\.venv\Scripts\Activate.ps1
```

```bash
# Linux/macOS
source .venv/bin/activate
```

Then install the runtime and development requirements:

```bash
python -m pip install -r requirements.txt
python -m pip install -r requirements-dev.txt
python -m coverage run --source=src,app -m pytest tests -q
python -m coverage report -m
```
