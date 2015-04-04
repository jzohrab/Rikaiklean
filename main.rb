# Takes a file as input, and cleans it up.

def get_data(filename)
  lines = File.read(filename).
    split("\n").
    map { |lin| lin.strip }.
    delete_if { |lin| lin == "" }.
    delete_if { |lin| lin =~ /^#/ }

  data = lines.map { |lin| lin.split("\t").map { |s| s.strip } }.
    delete_if { |record| record.size != 3 }

  # Delete any item where the first term is "contained" by the first
  # term in the line above it, but is not equal to the first term
  # above it.
  last_word = nil
  data.each_with_index do |record, index|
    curr_word = record[0]

    if (index == 0) # Skip the first
      last_word = curr_word
      next
    end

    if (last_word == curr_word)
      # Do nothing
    elsif (last_word =~ /^#{curr_word}/)
      record[0] = "DELETE_THIS"
    else
      last_word = curr_word
    end
  end

  data.delete_if { |rec| rec[0] == "DELETE_THIS" }

  # Combine different pronounciations, but same word and meaning.
  data.map! { |w, p, m| [p, w, m] }
  data = combine_common_first_terms(data)

  # Combine different words, but same pronounciation and meaning.
  data.map! { |p, w, m| [w, p, m] }
  data = combine_common_first_terms(data)

  data
end

# Given array of arrays with three fields each, combines the first
# field values if the next two field values are the same.  eg,
# [[ "a", "b", "c" ], ["a2", "b", "c"]] => [["a, a2", "b", "c"]]
def combine_common_first_terms(array)
  hsh = Hash.new { |h, k| h[k] = Hash.new { |h2, k2| h2[k2] = [] } }
  array.each do |a, b, c|
    hsh[b][c] << a
    hsh[b][c].uniq! if hsh[b][c].size > 1
  end
  ret = []
  hsh.keys.inject(ret) do |m1, b|
    hsh[b].keys.inject(m1) do |m2, c|
      m2 << [hsh[b][c].join(", "), b, c]
    end
  end
  ret
end


def rate_sort_order(definition)
  # (P) = Priority, so sort high
  return 1 if definition =~ /\(P\)$/
  # ok|K = Obsolete, sort low
  return 99 if definition =~ /^\(.*o[kK].*\)/
  return 50
end


# Main
data = get_data(ARGV[0])

data.map { |d| d[3] = rate_sort_order(d[2]) }
# Rate the data
# Ref http://www.csse.monash.edu.au/~jwb/wwwjdicinf.html#code_tag
# P - goes to top
# (ok) or (oK) goes to bottom
# data.
#   map { |d| d[3] = 50; d }.
#   map { 

data.sort! { |a, b| a[3] <=> b[3] }
data.map! { |d| d[0..2].join("\t") }

puts data
