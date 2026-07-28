# Asking Teachy questions

Everything Teachy knows is markdown and code in three git repos. On top of that
sits a generated knowledge graph spanning all three, so a question can be
answered without a person who remembers.

**The graph is a view. The markdown is the truth.** Never edit the graph; if it
is wrong, rebuild it.

## Which tool answers which question

| Question | Tool |
|----------|------|
| *Why* is it like this? | `gbrain search "<question>"` - semantic, over decisions and incidents |
| *Where* does this live, what touches it? | `graphify explain` - structural, over code |
| Is it already known-broken? | `engineering/known-issues.md` |

gbrain is a view over the same git-backed markdown, rebuilt on every commit. It
is never written to by hand - see [0009](decisions/0009-gbrain-indexes-the-brain.md).

Semantic search is currently keyword/FTS only: gbrain was initialised without an
embedding key. It already beats grep; it is not yet true semantic similarity.

## The graph

```
C:\Users\vedan\teachy\graph\teachy-graph.json
```

3,300+ nodes across teachy-app, teachy-web and teachy-brain. Node IDs are
prefixed with their repo, so you can always tell where an answer came from.

### Explain something

```bash
graphify explain "MicrophoneRecorder" --graph graph/teachy-graph.json
```

Returns what it is, which file and line it lives at, and everything connected to
it — callers, callees, implementations.

### How do two things connect?

```bash
graphify path "KeySetup" "openRouterKey" --graph graph/teachy-graph.json
```

Shortest path between any two nodes, across repo boundaries. Useful for "does the
website actually depend on this?" and "what breaks if I delete this?"

### Rebuild after changes

```bash
pwsh teachy-brain/scripts/rebuild-graph.ps1
```

Re-extracts all three repos and re-merges. Takes about a minute. Run it after a
refactor, a new decision record, or a new incident.

## Where to look when the graph is not the right tool

The graph is good at structure — what connects to what. It is bad at *why*. For
why, read the markdown:

| Question | Where |
|----------|-------|
| Why is it built this way? | `decisions/` |
| What broke, and what did we learn? | `engineering/incidents/` |
| What is still wrong? | `engineering/known-issues.md` |
| How does the whole thing fit together? | `engineering/architecture.md` |
| What is the product, and for whom? | `company/what-teachy-is.md` |
| How is a course designed? | `product/course-design.md` |
| What shipped when? | `launch/changelog.md` |

## The rule for keeping this true

When a decision gets made, write it down here **as a decision record**, not as a
commit message that scrolls away. A commit says what changed; a decision record
says what we now believe and what would change our mind.

Every record follows the same shape: the question, the decision, why, what it
costs us, and when to revisit. The "what it costs us" section is not optional —
a decision record with no downside listed is marketing, and nobody trusts it
later.

## Adding to the brain

1. Write markdown. Put it in the folder that matches the question it answers.
2. Link related records with normal relative links.
3. Commit.
4. Rebuild the graph.

There is no database, no account, and no service to keep alive. That is the
point — see [decision 0006](decisions/0006-git-and-graphify-as-the-company-memory.md).
