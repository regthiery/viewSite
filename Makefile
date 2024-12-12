
# Variables
QCMGEN   = ./tools/qcmGen.pl
INDEXGEN = ./tools/indexGen.pl
PAGEGEN  = ./tools/pageGen.pl
FICHEGEN = ./tools/ficheGen.pl

SAFARI='Safari.app'
CHROME='Google Chrome.app'
BROWSER=$(CHROME)
LOCAL0=html/
LOCAL1=http://localhost:8080/rocksandwalk/
DIST=https://geocool.fr
DIST3=https://rocksandwalk.netlify.app/html

CPANEL=https://owl.o2switch.net:2083/
USER=thre9886
FTP_SERVER = owl.o2switch.net


INDEX=index

DATA_DIR = data
LOCAL_HTML_DIR = html
CSS_DIR = $(DATA_DIR)/css
TEST_DIR = ~/sites/rocksandwalk/gertrude/netlify
TEST_HTML_DIR = $(TEST_DIR)/html
TEST_CSS_DIR = $(TEST_HTML_DIR)/css
REMOTE_DIR = /public_html 

INDEX_FILES = $(shell find $(DATA_DIR) -type f -name 'index*.txt')
PAGE_FILES = $(shell find $(DATA_DIR) -type f -name 'page*.txt')
FICHE_FILES = $(shell find $(DATA_DIR) -type f -name 'fiche*.txt')
QCM_FILES = $(shell find $(DATA_DIR) -type f -name 'qcm*.txt')

# Cibles
.PHONY: all clean copy

all: ensure_dirs run_index run_pagegen run_fichegen run_qcmgen 

# S'assurer que les dossiers existent
ensure_dirs:
	@mkdir -p $(LOCAL_HTML_DIR)
	@mkdir -p $(TEST_DIR)
	@mkdir -p $(TEST_CSS_DIR)  
	@mkdir -p $(TEST_HTML_DIR)  
	@mkdir -p $(TEST_HTML_DIR)/Images  
	@mkdir -p $(TEST_HTML_DIR)/FS
	@mkdir -p $(TEST_HTML_DIR)/GEOR
	@mkdir -p $(TEST_HTML_DIR)/TDU
	@mkdir -p $(TEST_HTML_DIR)/FS/Images  
	@mkdir -p $(TEST_HTML_DIR)/GEOR/Images  
	@mkdir -p $(TEST_HTML_DIR)/TDU/Images  

sync:
	rsync -av --include='*/' --include='*.mp4'      --exclude='*' data/ html/
	rsync -av --include='*/' --include='*.jpg'      --exclude='*' data/ html/
	rsync -av --include='*/' --include='*.png'      --exclude='*' data/ html/
	rsync -av --include='*/' --include='*.webp'     --exclude='*' data/ html/
	rsync -av --include='*/' --include='*.jpeg'     --exclude='*' data/ html/
	rsync -av --include='*/' --include='*.gif'      --exclude='*' data/ html/
	rsync -av --include='*/' --include='*.svg'      --exclude='*' data/ html/
	rsync -av --include='*/' --include='*.pdf'      --exclude='*' data/ html/
	rsync -av --include='*/' --include='*.css'      --exclude='*' data/ html/
	rsync -av --include='*/' --include='.htaccess'  --exclude='*' data/ html/
	rsync -av --include='*/' --include='*.html'     --exclude='*' data/ html/
	rsync -av --include='*/' --include='*.css'      --exclude='*' data/ html/


run_index:
	for file in $(INDEX_FILES); do \
		perl $(INDEXGEN) $$file styles; \
	done

run_pagegen: ensure_dirs $(PAGE_FILES)
	for file in $(PAGE_FILES); do \
		perl $(PAGEGEN) $$file styles; \
	done
	

run_fichegen: ensure_dirs $(FICHE_FILES)
	for file in $(FICHE_FILES); do \
		perl $(FICHEGEN) $$file  styles; \
	done

run_qcmgen: ensure_dirs $(QCM_FILES)
	for file in $(QCM_FILES); do \
		perl $(QCMGEN) $$file styleqcm1; \
	done
	
run:	
	perl $(FICHEGEN) $(DATA_DIR)/TDU/fiche01 $(HTML_DIR)/TDU styles

# Copier les fichiers CSS générés dans le dossier Netlify
copy:
	rsync -av  $(CSS_DIR)/              	  $(TEST_CSS_DIR)/
	rsync -av  $(LOCAL_HTML_DIR)/             $(TEST_HTML_DIR)
	rsync -av  $(LOCAL_HTML_DIR)/Images/      $(TEST_HTML_DIR)/Images
	rsync -av  $(LOCAL_HTML_DIR)/FS/Images/   $(TEST_HTML_DIR)/FS/Images
	rsync -av  $(LOCAL_HTML_DIR)/GEOR/Images/ $(TEST_HTML_DIR)/GEOR/Images
	rsync -av  $(LOCAL_HTML_DIR)/TDU/Images/  $(TEST_HTML_DIR)/TDU/Images

view0:
	open -a $(BROWSER) $(LOCAL0)/$(INDEX).html

view1:
	open -a $(BROWSER) $(LOCAL1)/$(INDEX).html

view2:
	open -a $(BROWSER) $(DIST)/$(INDEX).html

view3:
	open -a $(BROWSER) $(DIST3)/$(INDEX).html


# Nettoyer les fichiers générés
clean:
	rm -rf $(HTML_DIR)/*.html
	rm -rf $(TEST_HTML_DIR)/*.html
	
deploy:
	@echo "Synchronisation avec $(FTP_SERVER)..."
	lftp $(FTP_SERVER) -e "set ftp:ssl-allow no; mirror -R --parallel=5 $(LOCAL_HTML_DIR) $(REMOTE_DIR); bye"
	
