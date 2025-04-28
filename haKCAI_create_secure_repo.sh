# Auto-versioned repo creation
TARGET_DIR="hakcAI-python-secure-repo-template"
VERSION=1

while [ -d "${TARGET_DIR}" ]; do
    VERSION=$((VERSION+1))
    TARGET_DIR="hakcAI-python-secure-repo-template_v${VERSION}"
done

mkdir "${TARGET_DIR}" && cd "${TARGET_DIR}"

# Base files
echo "__pycache__/
*.pyc
*.pyo
*.pyd
env/
venv/
.env
build-metadata.json
sbom.json
" > .gitignore

echo "MIT License Template" > LICENSE

# Enhanced .env.example
cat > .env.example <<'EOF'
# Example environment variables
SERVICE_API_SALT=EXAMPLE_RANDOM_SALT_1234567890
SERVICE_USERNAME_HASH=EXAMPLE_HASHED_SERVICE_USERNAME_BASED_ON_SALT
SERVICE_API_KEY_HASH=EXAMPLE_HASHED_SERVICE_API_KEY_BASED_ON_SALT
EOF

# Requirements
echo "python-dotenv
tqdm
cyclonedx-bom
pip-audit
pre-commit
black
flake8
questionary" > requirements.txt

mkdir -p src tests scripts .github/workflows .github/ISSUE_TEMPLATE

# README
cat > README.md <<'EOF'
# hakcAI Secure Python Repo Template

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Python](https://img.shields.io/badge/python-3.10%2B-blue)
![Pip Audit](https://img.shields.io/badge/pip--audit-passing-brightgreen)
![Security](https://img.shields.io/badge/security-hardened-critical)
[![First Timers Only](https://img.shields.io/badge/first--timers--only-friendly-brightgreen.svg)](https://www.firsttimersonly.com/)

## Vibe Coding Instructions
- Code must feel structured, clear, and secure.
- Never leak secrets. Respect .env.
- All code must pass secret scanning, linting, SBOM generation.
- Follow aesthetic clean coding (Black formatting).
- Keep the security-first mindset in every change.

## AI Assistant Prompt
> "Assist with secure Python project respecting .env protections, salt+hash environment data, enforce Black and Flake8 compliance, avoid insecure packages. SBOM must be updated on dependency change. No hardcoded secrets. Functional, minimalistic, secure code only."
EOF

# Installer with secure .env generation
cat > installer.sh <<'EOF'
#!/bin/bash
set -e

python3 -m venv env
source env/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
pip install pre-commit black flake8 cyclonedx-bom pip-audit

# Generate secure .env if missing
if [ ! -f .env ]; then
  echo "No .env file detected. Generating a secure one..."
  python3 scripts/create_secure_env.py
fi

cyclonedx-py -o sbom.json
pip-audit || echo "pip audit completed with warnings."
python3 -c 'import platform, json, pkg_resources; json.dump({"python_version": platform.python_version(),"platform": platform.platform(),"installed_packages":{d.project_name:d.version for d in pkg_resources.working_set}}, open("build-metadata.json", "w"), indent=4)'
pre-commit install

echo "Setup complete."
EOF
chmod +x installer.sh

# Secure .env Creator
cat > scripts/create_secure_env.py <<'EOF'
#!/usr/bin/env python3
import os
import binascii
import hashlib
import questionary
from questionary import Style

style = Style([
    ('qmark', 'fg:#ff9d00 bold'),
    ('question', 'bold'),
    ('answer', 'fg:#00ff00 bold'),
    ('pointer', 'fg:#ff9d00 bold'),
    ('highlighted', 'fg:#ff9d00 bold'),
    ('selected', 'fg:#00ff00 bold'),
])

def create_env(path):
    entries = []
    while True:
        var_name = questionary.text("Enter variable base name (e.g., SERVICE_API)", style=style).ask()
        if not var_name:
            break
        secret_value = questionary.password(f"Enter secret for {var_name} (will be salted and hashed)", style=style).ask()
        salt = os.urandom(16)
        hash_value = hashlib.pbkdf2_hmac("sha256", secret_value.encode(), salt, 100000)
        entries.append(f"{var_name}_SALT={binascii.hexlify(salt).decode()}")
        entries.append(f"{var_name}_HASH={binascii.hexlify(hash_value).decode()}")

    with open(path, "w") as f:
        f.write("\n".join(entries))
    print(f"Secure .env file created at {path}")

if __name__ == "__main__":
    create_env(".env")
EOF

chmod +x scripts/create_secure_env.py

# Main app
cat > src/main.py <<'EOF'
#!/usr/bin/env python3
import logging
from tqdm import tqdm
from secure_env import secure_load_env

logging.basicConfig(level=logging.INFO)

def main():
    logging.info("Starting secure application...")
    env_data = secure_load_env()
    if env_data:
        logging.info("Secure environment variables loaded.")
    else:
        logging.warning("Environment variables missing.")
    for _ in tqdm(range(5), desc="Processing"):
        pass
    logging.info("Application complete.")

if __name__ == "__main__":
    main()
EOF

# Secure Env Loader
cat > src/secure_env.py <<'EOF'
#!/usr/bin/env python3
import os
from dotenv import load_dotenv

def secure_load_env():
    load_dotenv()
    variables = {}
    for key, value in os.environ.items():
        if key.endswith("_SALT") or key.endswith("_HASH"):
            variables[key] = value
    return variables
EOF

# Simple Unit Test
cat > tests/test_main.py <<'EOF'
import unittest
from src.secure_env import secure_load_env

class TestSecureEnv(unittest.TestCase):
    def test_secure_env_load(self):
        result = secure_load_env()
        self.assertTrue(isinstance(result, dict))
        for k, v in result.items():
            self.assertTrue(k.endswith("_SALT") or k.endswith("_HASH"))

if __name__ == "__main__":
    unittest.main()
EOF

# GitHub Actions
cat > .github/workflows/secure_ci.yml <<'EOF'
name: Secure CI

on: [push, pull_request]

jobs:
  build-and-audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.x'
      - name: Install and Audit
        run: |
          python3 -m venv env
          source env/bin/activate
          pip install -r requirements.txt
          pip-audit
          cyclonedx-py -o sbom.json
EOF

# Issue Template
cat > .github/ISSUE_TEMPLATE/bug_report.md <<'EOF'
---
name: Bug Report
about: Report a bug to help us improve
title: ''
labels: bug
assignees: ''

---

**Describe the Bug**
Clear description of the problem.
EOF

# Pre-commit config
cat > .pre-commit-config.yaml <<'EOF'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: check-yaml
      - id: end-of-file-fixer
      - id: check-added-large-files

  - repo: https://github.com/zricethezav/gitleaks
    rev: v8.17.0
    hooks:
      - id: gitleaks

  - repo: https://github.com/psf/black
    rev: 23.11.0
    hooks:
      - id: black
        language_version: python3

  - repo: https://github.com/pycqa/flake8
    rev: 6.1.0
    hooks:
      - id: flake8
        language_version: python3
EOF

# Project board
cat > .github/project.yml <<'EOF'
name: Secure Template Project Board
body: Tracking secure Python repo template tasks.

columns:
  - name: To Do
    cards:
      - note: Set up repo
      - note: Configure CI
      - note: Install security scanning
  - name: In Progress
    cards:
      - note: Write main functionality
  - name: Done
    cards:
      - note: Installed pre-commit hooks
      - note: Created SBOM
EOF

# Security Policy
cat > SECURITY.md <<'EOF'
# Security Policy

If you discover a vulnerability, please email security@example.com.  
We will respond within 24 hours.  
Do not open a public issue for security problems.
EOF

# Commit Signing
cat > SIGNING.md <<'EOF'
# Commit Signing Guide

We recommend signing all commits with GPG keys.

1. Generate GPG key
2. Add it to GitHub
3. Use `git commit -S -m "message"`

[Guide](https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-commits)
EOF

# CONTRIBUTING
cat > CONTRIBUTING.md <<'EOF'
# Contributing

- Follow Vibe Coding philosophy.
- Never commit secrets.
- Always run pre-commit checks.
- Maintain SBOM.
- Format code with Black, lint with Flake8.
EOF

# AIBOM
cat > aibom.md <<'EOF'
# AI Bill of Materials

## AI Usage
No AI-generated runtime code. Assistive use only.

## Ethical Commitments
- No generated credentials.
- No undisclosed training datasets.
EOF

cd ..
zip -r "${TARGET_DIR}.zip" "${TARGET_DIR}"
