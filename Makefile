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
## spellcheck runs codespell with .ignore-words, idnits runs the Datatracker
## checks on the next submission version.
lint:: http-lint spellcheck
all:: idnits

rfc-http-validate ?= rfc-http-validate
.SECONDARY: $(drafts_xml)
.PHONY: http-lint
http-lint: $(addsuffix .http-lint.txt,$(addprefix .,$(drafts)))
.PHONY: .%.http-lint.txt
.%.http-lint.txt: %.xml $(DEPS_FILES)
	$(trace) $< -s http-lint $(rfc-http-validate) -q -m sf.json $<
	@touch $@

clean::
	-rm -f .*.http-lint.txt
