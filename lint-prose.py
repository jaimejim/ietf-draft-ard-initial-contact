#!/usr/bin/env python3
"""Deterministic prose lint for Internet-Draft markdown.

Checks the lines that a change adds against .prose-rules.toml: banned
phrases, negation-then-correction constructions, non-ASCII punctuation,
hedging density. No model is involved. Errors fail the build (exit 1),
warnings are printed only.

Base selection: PROSE_LINT_BASE env var; else the GitHub event payload
(push "before" sha, or the pull request base sha), fetched if missing;
else HEAD. Without a base version of the file, the whole file is checked.
Files named draft-x-tmpNNNN.md (i-d-template pre-commit copies) are
compared against draft-x.md.
"""
import json, os, re, subprocess, sys, tomllib

def sh(*cmd):
    r = subprocess.run(cmd, capture_output=True, text=True)
    return r.returncode, r.stdout

def base_sha():
    b = os.environ.get("PROSE_LINT_BASE")
    if b:
        return b
    ev = os.environ.get("GITHUB_EVENT_PATH")
    if ev and os.path.exists(ev):
        try:
            e = json.load(open(ev))
        except Exception:
            e = {}
        sha = (e.get("pull_request") or {}).get("base", {}).get("sha") or e.get("before")
        if sha and not set(sha) <= {"0"}:
            if sh("git", "cat-file", "-e", f"{sha}^{{commit}}")[0] != 0:
                sh("git", "fetch", "-q", "--depth=1", "origin", sha)
            if sh("git", "cat-file", "-e", f"{sha}^{{commit}}")[0] == 0:
                return sha
    return "HEAD"

def base_text(path, sha):
    orig = re.sub(r"-tmp\d+(?=\.md$)", "", path)
    rc, out = sh("git", "show", f"{sha}:{orig}")
    return out if rc == 0 else None

def prose_lines(text):
    """Yield (lineno, line) for prose only: after the abstract marker, outside fences, no attribute lines."""
    out, in_fence, started = [], False, False
    for i, line in enumerate(text.splitlines(), 1):
        if not started:
            if line.startswith("--- abstract"):
                started = True
            continue
        if re.match(r"^\s*(~~~|```)", line):
            in_fence = not in_fence
            continue
        if in_fence or not line.strip() or line.startswith(("{:", "#", "--- ")):
            continue
        out.append((i, line))
    return out

def main(argv):
    rules_path = ".prose-rules.toml"
    files = []
    it = iter(argv)
    for a in it:
        if a == "--rules":
            rules_path = next(it)
        else:
            files.append(a)
    rules = tomllib.load(open(rules_path, "rb"))
    sha = base_sha()
    errors = warnings = 0
    all_added = []

    def report(level, path, n, msg, line):
        nonlocal errors, warnings
        if level == "error":
            errors += 1
        else:
            warnings += 1
        print(f"{path}:{n}: {level}: {msg}\n    {line.strip()[:160]}")

    for path in files:
        new = open(path, encoding="utf-8").read()
        old = base_text(path, sha)
        old_lines = set(prose_lines(old) and [l for _, l in prose_lines(old)]) if old is not None else set()
        added = [(n, l) for n, l in prose_lines(new) if l not in old_lines]
        all_added.extend(l for _, l in added)
        for n, line in added:
            low = line.lower()
            for level in ("error", "warn"):
                for pat in rules["negation"].get(level, []):
                    if re.search(pat, line, re.I):
                        report(level, path, n, f"negation-then-correction /{pat[:40]}/", line)
                for ph in rules["phrases"].get(level, []):
                    if re.search(r"(?<![\w-])" + re.escape(ph) + r"(?![\w-])", low):
                        report(level, path, n, f'phrase "{ph}"', line)
                for pat in rules["patterns"].get(level, []):
                    if re.search(pat, line, re.I):
                        report(level, path, n, f"pattern /{pat[:40]}/", line)

    words = re.findall(r"[A-Za-z']+", " ".join(all_added).lower())
    if words:
        hedges = set(rules["density"]["hedges"])
        per100 = 100 * sum(w in hedges for w in words) / len(words)
        if per100 > rules["density"]["warn_per_100"]:
            warnings += 1
            print(f"warning: hedging density {per100:.2f} per 100 words over {len(words)} added words (threshold {rules['density']['warn_per_100']})")

    scope = "whole file" if sha == "HEAD" and not any(base_text(p, sha) for p in files) else f"lines added since {sha[:12]}"
    print(f"prose-lint: {len(all_added)} lines checked ({scope}): {errors} errors, {warnings} warnings")
    return 1 if errors else 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
