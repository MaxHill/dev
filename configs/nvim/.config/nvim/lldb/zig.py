"""Project-toolchain Zig formatters with bounded previews for interactive DAP use."""

import importlib.util
import json
import sys
import types

import lldb

PREVIEW_BYTES = 256
MAX_MAP_CAPACITY = 4096
_upstream = None


def raw(value):
    return value.GetNonSyntheticValue()


def child(value, name):
    result = raw(value).GetChildMemberWithName(name)
    if not result.IsValid():
        raise ValueError("missing field: " + name)
    return result


def decode(value, offset=0, length=None):
    """Keep the upstream decoder's unquoted-string interface, but bound all reads."""
    try:
        size = child(value, "len").GetValueAsUnsigned()
        if offset < 0 or offset > size:
            return "<unreadable>"
        count = size - offset if length is None else min(max(length, 0), size - offset)
        preview = min(count, PREVIEW_BYTES)
        if preview == 0:
            return ""
        data = child(value, "ptr").GetPointeeData(offset, preview)
        if not data.IsValid() or data.GetByteSize() < preview:
            return "<unreadable>"
        content = bytes(data.uint8)[:preview]
        escaped = json.dumps(content.decode("utf-8", errors="backslashreplace"), ensure_ascii=False)[1:-1]
        return escaped + ("… <len=%d>" % count if count > preview else "")
    except Exception:
        return "<unreadable>"


def byte_summary(value, _=None):
    return '"%s"' % decode(value)


def array_list_summary(value, _=None):
    try:
        items = child(value, "items")
        size = child(items, "len").GetValueAsUnsigned()
        capacity = child(value, "capacity").GetValueAsUnsigned()
        summary = "len=%d capacity=%d" % (size, capacity)
        if "u8" in (items.GetTypeName() or ""):
            summary += " items=" + byte_summary(items)
        return summary
    except Exception:
        return "<unknown ArrayList layout; expand raw fields>"


def split_summary(value, _=None):
    try:
        buffer = child(value, "buffer")
        index = child(value, "index")
        position = optional_summary(index) if (index.GetTypeName() or "").startswith("?") else index.GetSummary() or index.GetValue() or "?"
        return "buffer=%s index=%s" % (byte_summary(buffer), position)
    except Exception:
        return "<unknown SplitIterator layout; expand raw fields>"


class Optional:
    """Zig LLVM optional payload has been named both 'data' and 'payload'."""

    def __init__(self, value, _=None):
        self.value = raw(value)
        self.children = []

    def update(self):
        self.children = []
        try:
            if child(self.value, "some").GetValueAsUnsigned():
                for name in ("payload", "data"):
                    payload = self.value.GetChildMemberWithName(name)
                    if payload.IsValid():
                        self.children = [payload.Clone("child")]
                        return
        except Exception:
            pass
        # Unknown layouts should remain inspectable rather than hide real fields.
        if not self.value.GetChildMemberWithName("some").IsValid():
            self.children = [self.value.GetChildAtIndex(i) for i in range(self.value.GetNumChildren())]

    def has_children(self):
        return bool(self.children)

    def num_children(self):
        return len(self.children)

    def get_child_index(self, name):
        return 0 if self.children and name in ("child", "?") else -1

    def get_child_at_index(self, index):
        return self.children[index] if 0 <= index < len(self.children) else None


def optional_summary(value, _=None):
    try:
        if not child(value, "some").GetValueAsUnsigned():
            return "null"
        for name in ("payload", "data"):
            payload = raw(value).GetChildMemberWithName(name)
            if payload.IsValid():
                return payload.GetSummary() or payload.GetValue() or "<present; expand child>"
    except Exception:
        pass
    return "<unknown optional layout; expand raw fields>"


class HashMap:
    """Use known upstream entry rendering only after bounding metadata inspection."""

    def __init__(self, value, _=None):
        self.value = raw(value)
        self.provider = None
        self.capacity = None

    def update(self):
        self.provider = None
        self.capacity = None
        try:
            metadata = child(self.value, "metadata")
            if not metadata.GetValueAsUnsigned():
                return
            value_type = self.value.type
            for helper in self.value.target.FindFunctions("%s.dbHelper" % value_type.name, lldb.eFunctionNameTypeFull):
                args = helper.function.type.GetFunctionArgumentTypes()
                ptr_self, ptr_header, _ = args
                if ptr_self.GetPointeeType() == value_type:
                    header_type = ptr_header.GetPointeeType()
                    header = metadata.CreateValueFromAddress("header", metadata.deref.load_addr - header_type.size, header_type)
                    self.capacity = child(header, "capacity").GetValueAsUnsigned()
                    break
            if self.capacity is None or self.capacity > MAX_MAP_CAPACITY:
                return
            self.provider = _upstream._nvim_original_hashmap(self.value)
            self.provider.update()
        except Exception:
            self.provider = None

    def has_children(self):
        return self.num_children() > 0

    def num_children(self):
        return self.provider.num_children() if self.provider else self.value.GetNumChildren()

    def get_child_index(self, name):
        return self.provider.get_child_index(name) if self.provider else self.value.GetIndexOfChildWithName(name)

    def get_child_at_index(self, index):
        return self.provider.get_child_at_index(index) if self.provider else self.value.GetChildAtIndex(index)

    def get_capacity(self):
        return self.capacity or 0


def map_summary(value, _=None):
    provider = HashMap(value)
    provider.update()
    if provider.provider:
        return "len=%d capacity=%d" % (provider.num_children(), provider.capacity)
    try:
        size = child(value, "size").GetValueAsUnsigned()
        return "len=%d capacity=%s (raw fields)" % (size, provider.capacity if provider.capacity is not None else "unknown")
    except Exception:
        return "raw fields (unknown layout or capacity > %d)" % MAX_MAP_CAPACITY


def managed_map_summary(value, _=None):
    try:
        return map_summary(child(value, "unmanaged"))
    except Exception:
        return "<unknown HashMap layout; expand raw fields>"


def setup(debugger, upstream_path):
    """Called once per CodeLLDB session with the selected Zig's formatter path."""
    global _upstream
    try:
        spec = importlib.util.spec_from_file_location("nvim_zig_upstream", upstream_path)
        module = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = module
        spec.loader.exec_module(module)
        _upstream = module
        if hasattr(module, "zig_String_decode"):
            module.zig_String_decode = decode
        # Guard upstream summary calls too, not only the UI synthetic provider.
        if hasattr(module, "std_HashMapUnmanaged_SynthProvider"):
            module._nvim_original_hashmap = module.std_HashMapUnmanaged_SynthProvider
            module.std_HashMapUnmanaged_SynthProvider = HashMap
            module.std_HashMapUnmanaged_SummaryProvider = map_summary
        # LLDB resolves names in its interpreter globals, not just sys.modules.
        # runpy's transient module is not importable by the callback resolver.
        support = types.ModuleType("nvim_zig_lldb")
        support.byte_summary = byte_summary
        support.array_list_summary = array_list_summary
        support.split_summary = split_summary
        support.optional_summary = optional_summary
        support.Optional = Optional
        support.managed_map_summary = managed_map_summary
        sys.modules["nvim_zig_lldb"] = support
        debugger.HandleCommand("script import nvim_zig_upstream, nvim_zig_lldb")
        module.__lldb_init_module(debugger, {})
        language = "zig.lang" if debugger.GetCategory("zig.lang").IsValid() else "zig"
        for name in ("zig.compiler", "zig.stage2"):
            debugger.HandleCommand("type category disable " + name)
        for name in (language, "zig.std"):
            debugger.HandleCommand("type category enable " + name)
        debugger.HandleCommand('type synthetic add --category %s -x -l nvim_zig_lldb.Optional "^\\\\?"' % language)
        debugger.HandleCommand('type summary add --category %s -x -F nvim_zig_lldb.optional_summary "^\\\\?"' % language)
        debugger.HandleCommand('type summary add --category zig.std -x -F nvim_zig_lldb.managed_map_summary "^hash_map\\\\.HashMap\\\\(.*\\\\)$"')
        for type_name in ("[]u8", "[]const u8", "[:0]u8", "[:0]const u8"):
            debugger.HandleCommand('type summary add --category %s -F nvim_zig_lldb.byte_summary "%s"' % (language, type_name))
        debugger.HandleCommand('type summary add --category zig.std -x -F nvim_zig_lldb.array_list_summary "^(array_list|array_list_aligned)\\..*"')
        debugger.HandleCommand('type summary add --category zig.std -x -F nvim_zig_lldb.split_summary "^mem\\.SplitIterator\\(.*\\)$"')
    except Exception as error:
        print("Zig DAP: formatter setup failed for %s: %s. Raw LLDB values remain available." % (upstream_path, error))
