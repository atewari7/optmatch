################################################################################
### Useful tasks for developing, not required to build the R package
################################################################################

R: .local/optmatch/INSTALLED
	R_PROFILE=interactive.R R -q --no-save 

### Package release scripts ###

VERSION=0.7-6
RELEASE_DATE=`date +%Y-%m-%d`
PKG=optmatch_$(VERSION)

# depend on the makefile so that updates to the version number will force a rebuild
# `git archive` doesn't export unarchived directories, so we export a .tar and untar it
# the code must be checked in to force a new export
$(PKG): Makefile R/* tests/* inst/tests/* man/* inst/examples/*
	rm -rf $(PKG)
	rsync -a --exclude-from=.gitignore --exclude=.git* --exclude Makefile \
		--exclude=DESCRIPTION.template --exclude=NAMESPACE.static \
		--exclude=interactive.R . $(PKG)

$(PKG)/DESCRIPTION: $(PKG) DESCRIPTION.template 
	sed s/VERSION/$(VERSION)/ DESCRIPTION.template | sed s/DATE/$(RELEASE_DATE)/ > $(PKG)/DESCRIPTION

$(PKG)/NAMESPACE: $(PKG) $(PKG)/DESCRIPTION
	mkdir -p $(PKG)/man
	R -e "library(roxygen2); roxygenize('$(PKG)')"
	cat NAMESPACE.static >> $(PKG)/NAMESPACE

$(PKG).tar.gz: $(PKG) $(PKG)/DESCRIPTION $(PKG)/NAMESPACE ChangeLog NEWS R/* data/* demo/* inst/* man/* src/relax4s.f tests/*
	R --vanilla CMD build $(PKG)

check: $(PKG).tar.gz
	R --vanilla CMD Check --as-cran --no-multiarch $(PKG).tar.gz

release: check
	git tag -a $(VERSION)
	@echo "Upload $(PKG) to cran.r-project.org/incoming"
	@echo "Email to CRAN@R-project.org, subject: 'CRAN submission optmatch $(VERSION)'"

# depend on this file to decide if we need to install the local version
.local/optmatch/INSTALLED: $(PKG).tar.gz
	mkdir -p .local
	R --vanilla CMD Install --no-multiarch --library=.local $(PKG).tar.gz
	echo `date` > .local/optmatch/INSTALLED

# test is just the internal tests, not the full R CMD Check
test: .local/optmatch/INSTALLED
	R --vanilla -q -e "library(optmatch, lib.loc = '.local'); library(testthat); test_package('optmatch')"

clean:
	git clean -xfd

package: $(PKG).tar.gz
