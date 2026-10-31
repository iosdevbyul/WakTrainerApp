# WakTrainer CI Auto-Merge Smoke Test

This documentation-only PR verifies the automatic merge workflow introduced in PR #130.

Expected outcome:
1. The existing `CI` workflow completes successfully.
2. The `Auto Merge After CI` workflow validates that this open, non-draft PR is authored by `iosdevbyul` and targets `main`.
3. The exact tested commit is squash-merged automatically, without a manual merge action.

This PR does not modify iOS application code, assets, dependencies, security, or settings.

If automatic merging fails, inspect the `Auto Merge After CI` workflow logs and repository Actions token write permissions. Do not manually merge the smoke-test PR because that would invalidate the test.
