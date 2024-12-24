import os, sys  # Multiple imports on one line (E401)

def foo():
  print("Hello, world!")  # Print statement found (T201)

def bar():
  x = { 'a': 1, 'b': 2 }  # Whitespace inside braces (E201)
  y = [1, 2, 3, ]  # Trailing comma in list (E231)
  return x, y

foo()
bar()