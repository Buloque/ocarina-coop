## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.

Rules:
- When graphify-out/graph.json exists, run `graphify query "<question>"` before broad source searches. Use `graphify path "<A>" "<B>"` and `graphify explain "<concept>"` for focused exploration. Verify graph claims against source. Direct inspection and targeted searches remain allowed when results are missing, stale, ambiguous or insufficient.
- Dirty graphify-out/ files are expected after hooks or incremental updates; dirty graph files are not a reason to skip graphify. Only skip graphify if the task is about stale or incorrect graph output, or the user explicitly says not to use it.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
- Keep graphify-out/ ignored and local. Use `graphify extract . --code-only --no-cluster` for the initial local AST graph; never enable hosted extraction, cloud indexing or optional integrations without authorization. Respect .graphifyignore. Follow docs/UPSTREAM_REUSE_POLICY.md and the P1 gates in docs/ROADMAP.md before functional work.
