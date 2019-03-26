#!/bin/bash
CC := gcc
AR := ar rvs
STD := -std=c99
DEBUG := -g3
LEX := flex
PARSE := bison
_PATH := C/
API := mikrotikapi
SIM := simulate
LIB_PATH := ./$(_PATH)lib
OBJ_PATH := ./$(_PATH)obj
SRC_PATH := ./$(_PATH)src
BIN_PATH = ./$(_PATH)bin
INC_PATH = ./$(_PATH)include
OBJ := $(OBJ_PATH)/$(API).o $(OBJ_PATH)/functions.o
INC := $(INC_PATH)/mainheader.h
LIB := $(LIB_PATH)/lib$(API).a
CFLAGS := $(DEBUG) $(STD)

.PHONY: all API clean restruct

all: DIRECTORY API

DIRECTORY: $(OBJ_PATH) $(BIN_PATH) $(LIB_PATH)

$(LIB_PATH):
	$(if ifeq test -d "$(LIB_PATH)" 0, @mkdir -p $(LIB_PATH))

$(OBJ_PATH):
	$(if ifeq test -d "$(OBJ_PATH)" 0, @mkdir -p $(OBJ_PATH))

$(BIN_PATH):
	$(if ifeq test -d "$(BIN_PATH)" 0, @mkdir -p $(BIN_PATH))

API: $(LIB)
	$(CC) $(OBJ_PATH)/$(API).o -l$(API) -L $(LIB_PATH) -o $(BIN_PATH)/$(API)

$(LIB): $(OBJ)
	$(AR) $(LIB) $(OBJ)

$(OBJ_PATH)/$(API).o: $(INC) $(SRC_PATH)/$(API).c
	$(CC) -c $(SRC_PATH)/$(API).c -o $(OBJ_PATH)/$(API).o $(CFLAGS)

$(OBJ_PATH)/functions.o: $(INC) $(SRC_PATH)/functions.c
	$(CC) -c $(SRC_PATH)/functions.c -o $(OBJ_PATH)/functions.o $(CFLAGS)

clean:
	rm -f $(BIN_PATH)/*
	rm -f $(OBJ_PATH)/*.o
	rm -rf $(OBJ_PATH) $(LIB_PATH) $(BIN_PATH)

restruct:
	make clean
	make all
