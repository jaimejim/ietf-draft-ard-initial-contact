LIBDIR := lib
-include $(LIBDIR)/main.mk

$(LIBDIR)/main.mk:
ifneq (,$(shell grep "path *= *$(LIBDIR)" .gitmodules 2>/dev/null))
	git submodule sync
	git submodule update --init
else
ifneq (,$(wildcard $(ID_TEMPLATE_HOME)))
	ln -s "$(ID_TEMPLATE_HOME)" $(LIBDIR)
else
	git clone -q --depth 10 -b main \
	    https://github.com/martinthomson/i-d-template $(LIBDIR)
endif
endif

## Additional checks, run as part of the default build.
## http-lint validates the http-message examples (as in httpwg/http-extensions),
## codespell-lint runs codespell with .ignore-words, prose-lint checks added
## prose against .prose-rules.toml, idnits runs the Datatracker checks on the
## next submission version.
lint:: http-lint codespell-lint prose-lint
all:: idnits

rfc-http-validate ?= rfc-http-validate
.SECONDARY: $(drafts_xml)
.PHONY: http-lint
http-lint: $(addsuffix .http-lint.txt,$(addprefix .,$(drafts)))
.PHONY: .%.http-lint.txt
.%.http-lint.txt: %.xml $(DEPS_FILES)
	$(trace) $< -s http-lint $(rfc-http-validate) -q -m sf.json $<
	@touch $@

# The template's own spellcheck target assumes a venv, which CI does not have;
# codespell comes from requirements.txt instead.
codespell ?= codespell
.PHONY: codespell-lint
codespell-lint: $(drafts_source) $(DEPS_FILES)
	$(trace) spellcheck -s codespell $(codespell) -I .ignore-words $(drafts_source)

# prose-lint checks the lines a change adds against .prose-rules.toml
# (banned phrases, negation-then-correction, non-ASCII punctuation, hedging).
.PHONY: prose-lint
prose-lint: $(drafts_source)
	$(trace) prose -s prose-lint $(python) lint-prose.py --rules .prose-rules.toml $(drafts_source)

clean::
	-rm -f .*.http-lint.txt
