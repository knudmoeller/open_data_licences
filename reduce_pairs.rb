require 'set'

# reads a 2-column CSV file, assumes rows "a,b" and "b,a" are identical,
# removes duplicates, and outputs result to stdout
#
# achieved by using sets (where [a, b] == [b, a])

sets = Set.new

csv = File.open("queries/shared_datasets.csv")
csv.each_line do |pair|
  arr = pair.chomp.split(",")
  set = Set.new(arr)
  sets << set
end
csv.close

sets.each do |pair|
  puts pair.to_a.join(",")
end
