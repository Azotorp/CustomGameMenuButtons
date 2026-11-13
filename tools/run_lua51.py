#!/usr/bin/env python3
"""Run a Lua script with a real Lua 5.1 runtime from the Lupa wheel.
Install: python3 -m pip install lupa
Alternative: lua5.1 tests/harness.lua AddOns
"""
import sys
from lupa.lua51 import LuaRuntime
lua=LuaRuntime(unpack_returned_tuples=True)
lua.globals().arg=lua.table_from({i:a for i,a in enumerate(sys.argv[1:])})
lua.execute('assert(_VERSION=="Lua 5.1"); assert(loadfile(arg[0]))()')
