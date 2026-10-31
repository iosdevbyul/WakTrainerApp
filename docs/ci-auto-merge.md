# WakTrainer: CI-gated automatic PR merging

## Operating rule

**Only the user decides and instructs new work.** This automation never creates tasks, starts Codex, opens branches or PRs, or updates Trello.

After the user directs work and its PR is created, the repository automatically squash-merges the PR into `main` **when the existing `CI` workflow succeeds**, provided:

- The PR belongs to `iosdevbyul/WakTrainerApp`, is authored by `iosdevbyul`, targets `main`, and is not a draft.
- The successful CI run tested the **current** PR head commit SHA.
- The PR does not have the `manual-qa` label.
- It does not modify `.github/workflows/` or `.github/actions/`. Changes to automation need review and manual merging.
- GitHub branch protection and required checks allow merging. Never force-push or use admin bypass.

**App and UI changes are eligible by default** because the user requested automatic merging after CI success. For any task that requires real-device verification *before merging*, create a Draft PR or add `manual-qa` before CI completes. Passing CI alone does not validate live activities, HealthKit, AirPods, or other hardware-dependent behaviors.

## First-time setup

1. Manually merge the automation setup PR after its own CI succeeds. A `workflow_run` workflow executes only when its YAML is present on the default branch.
2. In GitHub repository **Settings → Actions → General → Workflow permissions**, ensure `GITHUB_TOKEN` has the required contents and pull-request write permissions. Repository or organization settings can restrict them.
3. In **Settings → Branches** or **Rulesets**, protect `main`: require pull requests, require the `CI / build-and-test` check, and ideally require PR branches to be up to date. Avoid requiring a review from the PR's sole author.
4. Create the opt-out label once:

```bash
gh label create manual-qa --repo iosdevbyul/WakTrainerApp --color D93F0B --description "Requires on-device validation before manual merge"
```

The workflow performs a conditional `gh pr merge` itself; GitHub's separate **Allow auto-merge** toggle is not required.

## Sequence

1. The user requests a task.
2. We create a feature branch, implement and test, and open a PR.
3. GitHub Actions `CI` runs `build-and-test`.
4. On CI success, `Auto Merge After CI` resolves the PR from its tested commit SHA, verifies trust, labels and change paths, then uses a SHA-locked squash merge.
5. **Stop.** Wait for a new user instruction. Do not start the next development task automatically.

## Diagnostic checks

- For a PR requiring manual verification, use a Draft PR or add `manual-qa` before CI finishes.
- If CI fails, no merge occurs.
- If the PR remains open after CI succeeds, inspect **Auto Merge After CI** run logs. A missing token permission, changed PR head, branch protection, or a Draft/blocked PR can prevent merging.
- If `main` advances while CI runs, require a fresh CI run after updating the branch when protected checks demand an up-to-date branch.
- The setup PR is intentionally excluded from auto-merging because it modifies workflow files.

This is the **merge automation only**. It does not schedule or autonomously direct Codex work.
