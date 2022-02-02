######################################################
# File:                  Makefile                    #
# Application Name:      your-application-name       #
# Functionality:         Installation and Setup      #
# Author:                Adam Allgood                #
# Date Makefile created: 2022-02-22                  #
######################################################

# --- Rules ---

.PHONY: permissions
.PHONY: dirs

# --- make install ---

install: permissions dirs

# --- permissions ---

permissions:
	chmod 755 ./drivers/*.sh

# --- dirs ---

dirs:
	mkdir -p ./logs
	mkdir -p ./work
