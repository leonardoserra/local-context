---
name: local-context-crn
description: Alias of local-context-code-review-mapping-navigator (crn = code review navigator). Walks the user through a feature's CODE_REVIEW_MAPPING.md one group at a time in their IDE, answering questions and <crn> comments and applying review edits to the feature branch. Run by the user as local-context-crn <feature_name> [group number] [ide].
argument-hint: "<feature_name> [group number] [ide name]"
disable-model-invocation: true
---

# local-context-crn

Alias. Read `<this skill folder>/../local-context-code-review-mapping-navigator/SKILL.md` and follow it
exactly, with this call's arguments. In it, `<skill_dir>` is
`<this skill folder>/../local-context-code-review-mapping-navigator`.
