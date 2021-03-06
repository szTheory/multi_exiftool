# encoding: utf-8
# frozen_string_literal: true

require 'date'
require 'set'

module MultiExiftool

  # Representing (tag, value) pairs of metadata.
  # Access via bracket-methods or dynamic method-interpreting via
  # method_missing.
  class Values

    @tag_map = {}

    def initialize values
      @values = {}
      values.map do |tag,val|
        unified_tag = Values.unify_tag(tag)
        Values.tag_map[unified_tag] = tag
        val = val.kind_of?(Hash) ? Values.new(val) : val
        @values[unified_tag] = val
      end
    end

    # Gets the (posible converted) value for a tag
    # (tag will be unified, i.e. FNumber, fnumber or f_number
    # can be used for FNumber)
    def [](tag)
      unified_tag = Values.unify_tag(tag)
      convert(unified_tag, @values[unified_tag])
    end

    # Gets the original tag names of this instance
    def tags
      @values.keys.map {|tag| Values.tag_map[tag]}
    end

    # Generate a hash representation of this instance
    # with original tag names es keys and converted
    # values as values
    def to_h
      @values.inject(Hash.new) do |h, a|
        tag, val = a
        h[Values.tag_map[tag]] = convert(Values.unify_tag(tag), val)
        h
      end
    end

    alias to_hash to_h

    private

    class << self

      attr_reader :tag_map

      def unify_tag tag
      tag.gsub(/[-_]/, '').downcase
      end

    end

    def method_missing tag, *args, &block
      res = self[Values.unify_tag(tag.to_s)]
      if res && block_given?
        if block.arity > 0
          yield res
        else
          res.instance_eval &block
        end
      end
      res
    end

    def convert tag, val
      return val unless val.kind_of?(String)
      case tag
      when 'partofset', 'track'
        return val
      end
      case val
      when /^(\d{4}):(\d\d):(\d\d) (\d\d):(\d\d)(?::(\d\d)(?:\.\d+)?)?((?:[-+]\d\d:\d\d)|(?:Z))?(?: *DST)?$/
        arr = $~.captures[0,6].map {|cap| cap.to_i}
        zone = $7
        zone = '+00:00' if zone == 'Z'
        arr << zone if zone
        Time.new(*arr)
      when %r(^(\d+)/(\d+)$)
        Rational($1, $2)
      else
        val
      end
    end

  end

end
