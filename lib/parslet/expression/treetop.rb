class Parslet::Expression::Treetop
  class Parser < Parslet::Parser # :nodoc:
    root(:expression)
    
    rule(:expression) { alternatives }
    
    # alternative 'a' / 'b'
    rule(:alternatives) {
      (simple >> (spaced('/') >> simple).repeat).as(:alt)
    }
    
    # sequence by simple concatenation 'a' 'b'
    rule(:simple) { occurrence.repeat(1).as(:seq) }
    
    # occurrence modifiers
    rule(:occurrence) {
      atom.as(:repetition) >> spaced('*').as(:sign) |
      atom.as(:repetition) >> spaced('+').as(:sign) |
      
      atom.as(:maybe) >> spaced('?') | 
      atom
    }
    
    rule(:atom) { 
      spaced('(') >> expression.as(:unwrap) >> spaced(')') |
      dot |
      string |
      char_class
    }
    
    # a character class
    rule(:char_class) {
      (str('[') >>
        (str('\\') >> any |
        str(']').absnt? >> any).repeat(1) >>
      str(']')).as(:match) >> space?
    }
    
    # anything at all
    rule(:dot) { spaced('.').as(:any) }
    
    # recognizing strings
    rule(:string) {
      str('\'') >> 
      (
        (str('\\') >> any) |
        (str("'").absnt? >> any)
      ).repeat.as(:string) >> 
      str('\'') >> space?
    }
    
    # whitespace handling
    rule(:space) { match("\s").repeat(1) }
    rule(:space?) { space.maybe }
    
    def spaced(str)
      str(str) >> space?
    end
  end
  
  class Transform < Parslet::Transform # :nodoc:
    
    rule(:repetition => simple(:rep), :sign => simple(:sign)) { 
      min = sign=='+' ? 1 : 0
      Parslet::Atoms::Repetition.new(rep, min, nil) }
    rule(:alt => subtree(:alt))       { Parslet::Atoms::Alternative.new(*alt) }
    rule(:seq => sequence(:s))        { Parslet::Atoms::Sequence.new(*s) }
    rule(:unwrap => simple(:u))       { u }
    rule(:maybe => simple(:m))        { |d| d[:m].maybe }
    rule(:string => simple(:s))       { Parslet::Atoms::Str.new(s) }
    rule(:match => simple(:m))        { Parslet::Atoms::Re.new(m) }
    rule(:any => simple(:a))          { Parslet::Atoms::Re.new('.') }
  end
  
end
