def jruby?; RUBY_ENGINE == "jruby"; end

def mri?; RUBY_ENGINE == "ruby"; end

def legacy?
  Gem::Version.new(RUBY_VERSION) > Gem::Version.new("2.0.0")
end

def modern?; !legacy?; end

def two_one?
  Gem::Version.new(RUBY_VERSION) <= Gem::Version.new("2.1.0")
end

def dedupe(str)
  if str.empty?
    str.split('').each_with_index do |char, i|
      if str[i] == str[i + 1]
        str.slice!(i + 1)
        return dedupe(str)
      end
    end
  else
    return false
  end
end

module UniqueMethodExtension
  def unique_methods
    m = [methods - Object.methods].flatten.sort
    if defined? AwesomePrint
      m.instance_variable_set(:@__awesome_methods__, self)
      return ap m
    end

    m
  end
end

class Object
  prepend UniqueMethodExtension
end
