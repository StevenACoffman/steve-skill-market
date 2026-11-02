# Steve-Skill-Market

Agent Skills for Claude Code and the Pi coding agent, published as 14
[Agent Plugins](https://agent-plugins.org/specification). Each plugin is a directory
under `plugins/` with a `plugin.json` and a `skills/` directory.

## Install

### Claude Code

Add the marketplace once, then install the plugins you want:

```sh
claude plugin marketplace add StevenACoffman/steve-skill-market
claude plugin install family-tools@steve-skill-market
```

Claude Code shows a plugin's skills as `/<plugin>:<skill>`.

### Pi

Install the repository as a Pi package. Its `package.json` declares every plugin's
`skills/` directory:

```sh
pi install git:github.com/StevenACoffman/steve-skill-market
```

Pi lists every enabled skill on every request, so enable only what you use. Run
`pi config`, or narrow the package in your settings. This example suits a 32k-token
local model: the family's tools without the three long workflows, plus two subjects
(64 skills, about 8k tokens of listing):

```json
{
  "packages": [
    {
      "source": "git:github.com/StevenACoffman/steve-skill-market",
      "skills": [
        "plugins/family-tools/skills/*",
        "plugins/go-craft/skills/*",
        "plugins/testing-legacy/skills/*",
        "!book2skill",
        "!merge-skills",
        "!skillsaw-skill"
      ]
    }
  ]
}
```

book2skill, merge-skills and skillsaw-skill need about 64k tokens of context; at 32k
they are best effort. Point Pi at this package or at `~/.claude/skills`, never both:
the same skill would load twice.

## Plugins

| Plugin                | Skills | What it covers                                                                               |
| --------------------- | -----: | -------------------------------------------------------------------------------------------- |
| `family-tools`        |     12 | book2skill, merge-skills, skillsaw-skill, canonizer, and the linters and formatters they run |
| `third-party`         |      3 | crit, a third-party review tool                                                              |
| `webapp`              |     10 | Khan Academy's webapp codebase                                                               |
| `go-craft`            |     37 | Go application design: packages, dependency injection, errors, HTTP services, CLIs           |
| `sre`                 |     29 | SLOs and error budgets, alerting, incident response, toil, capacity                          |
| `strategy-leadership` |     25 | Architecture strategy, program governance, complexity diagnosis, organization design         |
| `software-design`     |     18 | Deep modules, information hiding, refactoring and incremental change                         |
| `testing-legacy`      |     18 | Go testing practice and safe change in legacy code                                           |
| `tool-reference`      |     17 | Terraform, gh, gqlgen, genqlient, sqlc, pgxpool, leafwiki, Go test tooling                   |
| `grpc`                |     15 | gRPC service design, testing, deployment, load balancing                                     |
| `data-systems`        |     11 | Replication, consistency, sharding, transactions, stream processing                          |
| `security`            |     10 | Least privilege, multi-party authorization, zero trust, supply chain, breakglass             |
| `integration`         |      9 | Messaging, queues, coupling, event-driven architecture                                       |
| `data-modeling`       |      6 | Stakeholder mapping, machine-learning data practice, and warehouse SQL guards                |

`./skill-list` prints every skill with its description, grouped by plugin.

## Repository Layout

- `plugins/<plugin>/skills/<skill>/` holds only what ships: `SKILL.md`, its
  `test-prompts.json`, and the reference files and scripts it names.
- `dev/<skill>/` holds development files: test results, merge audits, backlogs.
  `scripts/dev-files park` moves them out of the plugins and `scripts/dev-files restore`
  puts them back beside their skill, wherever that skill now lives.
- Skills that inspect the repository they are applied to run a bundled
  `scripts/current-state.sh`, which only reads files.
