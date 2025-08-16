# PatrolShield Copilot/AI Coding Agent Instructions

## Immediate Focus

Your job is to accelerate high-quality development of the PatrolShield security platform—especially the mobile and web admin dashboards—by following all project checklists, API docs, and engineering standards.

## Development Principles

- **Follow the checklist in `.github/mobile-development-instructions.md`** for mobile, or `frontend-development-instructions.md` for web.
- **Never skip, reorder, or omit checklist steps.** Each must be completed, tested, and verified before marking as done.
- **Integrate only real backend APIs** (see `docs/comprehensive-api-documentation.md`) using schemas and error handling.
- **Respect all access/permission rules** (see `docs/access_matrix.csv`).
- **Always use environment config for API URLs and credentials.**

## Output & Code Quality

- All code must be production-ready, readable, and modular.
- Each feature or fix must pass all applicable tests (unit, widget, integration).
- Use the shared code structure: `models/`, `services/`, `widgets/`.
- Commit messages must reference the checklist item and clearly describe the change.

## Prohibited

- No use of mock data or placeholder APIs.
- No skipping tests or quality gates.
- No out-of-order work or incomplete features.

## Success Criteria

- The modules specified in the current phase (users, sites, patrols, checkpoints) are fully functional, integrated with the backend, and pass all tests.
- Only expand to new modules after current scope is production-ready and validated.

*Your output must always align with the core project instructions, checklists, and API documentation.*