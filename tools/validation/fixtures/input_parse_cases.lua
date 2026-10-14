-- M2.1 parser cases: raw source text that must be rejected before validation.
return {
    { name = "function call", src = 'return { schema = print("x") }', expect = "only data literals" },
    { name = "string method", src = 'return { schema = ("x"):rep(10) }', expect = "only data literals" },
    { name = "global reference", src = 'return { schema = os }', expect = "only data literals" },
    { name = "loop code", src = 'while true do end', expect = "only data literals" },
    { name = "statement after table", src = 'return {} os.exit(1)', expect = "trailing content" },
    { name = "bytecode", src = "\27LuaQ", expect = "bytecode" },
    { name = "duplicate field", src = 'return { a = 1, a = 2 }', expect = "duplicate key a" },
    { name = "duplicate bracket key", src = 'return { [5] = 1, [5] = 2 }', expect = "duplicate key 5" },
    { name = "duplicate list and bracket key", src = 'return { 1, [1] = 2 }', expect = "duplicate key 1" },
    { name = "unterminated string", src = 'return { a = "x }', expect = "unterminated string" },
    { name = "unterminated table", src = 'return { a = 1', expect = "expected" },
    { name = "long string", src = 'return { a = [[x]] }', expect = "unexpected input" },
    { name = "top level not a table", src = 'return 5', expect = "top level must be a table" },
    { name = "nil value", src = 'return { a = nil }', expect = "nil value" },
    { name = "too deep", src = 'return {{{{{{{{{{1}}}}}}}}}}', expect = "nested too deeply" },
    { name = "empty input", src = '', expect = "only data literals" },
}
