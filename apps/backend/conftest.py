import os
import sys
from pathlib import Path

# Set dummy env vars BEFORE any app module is imported.
# Tests mock get_supabase() so real credentials are never used.
os.environ.setdefault("SUPABASE_URL", "https://test.supabase.co")
os.environ.setdefault("SUPABASE_SERVICE_ROLE_KEY", "test-service-role-key")
os.environ.setdefault("ALLOWED_ORIGINS", '["http://localhost:3000"]')

# Add the backend root to sys.path so `import main` and `import app.*` resolve
# whether pytest is run from the repo root, apps/backend, or tests/.
sys.path.insert(0, str(Path(__file__).parent))
