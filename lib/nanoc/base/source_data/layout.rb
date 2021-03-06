# encoding: utf-8

module Nanoc

  # Represents a layout in a nanoc site. It has content, attributes, an
  # identifier and a modification time (to speed up compilation).
  class Layout

    extend Nanoc::Memoization

    # @return [String] The raw content of this layout
    attr_reader :raw_content

    # @return [String] The filename pointing to the file containing this
    #   layout’s content
    attr_accessor :raw_filename

    # @return [Hash] This layout's attributes
    attr_reader :attributes

    # @return [String] This layout's identifier
    attr_accessor :identifier

    # Creates a new layout.
    #
    # @param [String] raw_content The raw content of this layout.
    #
    # @param [Hash] attributes A hash containing this layout's attributes.
    #
    # @param [String] identifier This layout's identifier.
    def initialize(raw_content, attributes, identifier, params={})
      if identifier.is_a?(String)
        identifier = Nanoc::Identifier.from_string(identifier)
      end

      @raw_content  = raw_content
      @attributes   = attributes.symbolize_keys_recursively
      @identifier   = identifier
    end

    # Requests the attribute with the given key.
    #
    # @param [Symbol] key The name of the attribute to fetch.
    #
    # @return [Object] The value of the requested attribute.
    def [](key)
      @attributes[key]
    end

    # Returns the type of this object. Will always return `:layout`, because
    # this is a layout. For items, this method returns `:item`.
    #
    # @api private
    #
    # @return [Symbol] :layout
    def type
      :layout
    end

    # Prevents all further modifications to the layout.
    #
    # @return [void]
    def freeze
      attributes.freeze_recursively
      identifier.freeze
      raw_content.freeze
    end

    # Returns an object that can be used for uniquely identifying objects.
    #
    # @api private
    #
    # @return [Object] An unique reference to this object
    def reference
      [ type, self.identifier ]
    end

    def inspect
      "<#{self.class} identifier=\"#{self.identifier}\">"
    end

    # @return [String] The checksum for this object. If its contents change,
    #   the checksum will change as well.
    def checksum
      attributes = @attributes.dup
      attributes.delete(:file)
      @raw_content.checksum + ',' + attributes.checksum
    end
    memoize :checksum

    def hash
      self.class.hash ^ self.identifier.hash
    end

    def eql?(other)
      self.class == other.class && self.identifier == other.identifier
    end

    def ==(other)
      self.eql?(other)
    end

    def marshal_dump
      [
        @raw_content,
        @attributes,
        @identifier
      ]
    end

    def marshal_load(source)
      @raw_content,
      @attributes,
      @identifier = *source
    end

  end

end
