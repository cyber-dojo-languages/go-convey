
lambda { |stdout,stderr,status|
  output = stdout + stderr
  return :amber if /FAIL(\s*)_\/sandbox(.*)\[build failed\]/.match(output)
  return :amber if /syntax error:/.match(output)
  return :red   if /FAIL/.match(output)
  return :green if /PASS/.match(output)
  return :amber
}
