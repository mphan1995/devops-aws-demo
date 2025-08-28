.PHONY: gitleaks bandit test sonar-up sonar-wait sonar-scan sonar-down check all
SONAR_HOST_URL ?= http://sonarqube:9000

gitleaks:
	docker run --rm -v $(PWD):/repo zricethezav/gitleaks:latest \
	  detect --source=/repo --config=/repo/.gitleaks.toml --verbose --redact

bandit:
	docker run --rm -v $(PWD):/app -w /app python:3.11-slim bash -lc "\
	  pip install --no-cache-dir bandit && \
	  bandit -r app -c bandit.yaml -lll -ii"

test:
	python3 -m pip install -U pip
	python3 -m pip install -r requirements.txt pytest pytest-cov
	pytest -q --maxfail=1 --disable-warnings --cov=app --cov-report=xml:coverage.xml

sonar-up:
	docker compose -f sonar/docker-compose.yml up -d

sonar-wait:
	@echo "Waiting for SonarQube..."; \
	until curl -sf $(SONAR_HOST_URL)/api/system/status | grep -q '"status":"UP"'; do \
	  sleep 5; echo -n "."; \
	done; echo " UP."

sonar-scan:
	@if [ -z "$$SONAR_TOKEN" ]; then echo "Export SONAR_TOKEN first"; exit 2; fi
	docker run --rm \
	  --network sonar_default \
	  -e SONAR_HOST_URL=$(SONAR_HOST_URL) \
	  -e SONAR_TOKEN=$$SONAR_TOKEN \
	  -v $(PWD):/usr/src \
	  sonarsource/sonar-scanner-cli


sonar-down:
	docker compose -f sonar/docker-compose.yml down -v

check: gitleaks bandit test
all: check sonar-scan
