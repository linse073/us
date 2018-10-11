include platform.mk

LUA_CLIB_PATH ?= 3rd/skynet/luaclib

LUA_INC ?= 3rd/skynet/3rd/lua

CFLAGS = -g -O2 -Wall -I$(LUA_INC) $(MYCFLAGS)

LUA_CLIB = lkcp

all : \
  $(foreach v, $(LUA_CLIB), $(LUA_CLIB_PATH)/$(v).so)

$(LUA_CLIB_PATH) :
	mkdir $(LUA_CLIB_PATH)

$(LUA_CLIB_PATH)/lkcp.so : lib-src/lkcp.c 3rd/kcp/ikcp.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -I3rd/kcp $^ -o $@	

clean :
	rm -f $(foreach v, $(LUA_CLIB), $(LUA_CLIB_PATH)/$(v).so)

cleanall : clean
	cd 3rd/skynet && $(MAKE) cleanall

