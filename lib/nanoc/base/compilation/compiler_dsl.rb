# encoding: utf-8

module Nanoc

  # Contains methods that will be executed by the site’s `Rules` file.
  #
  # Several methods accept patterns. These patterns can be either globs or
  # regular expressions.
  class CompilerDSL

    # Creates a new compiler DSL for the given collection of rules.
    #
    # @api private
    #
    # @param [Nanoc::RulesCollection] rules_collection The collection of
    #   rules to modify when loading this DSL
    def initialize(rules_collection)
      @rules_collection = rules_collection
    end

    # Creates a preprocessor block that will be executed after all data is
    # loaded, but before the site is compiled.
    #
    # @yield The block that will be executed before site compilation starts
    #
    # @return [void]
    def preprocess(&block)
      @rules_collection.preprocessor = block
    end

    # Creates a compilation rule for all items whose identifier match the
    # given pattern.
    #
    # This rule will be applicable to reps with a name equal to `:default`;
    # this can be changed by giving an explicit `:rep` parameter.
    #
    # @param [String] pattern A pattern matching identifiers of items that
    #   should be compiled using this rule
    #
    # @option params [Symbol] :rep (:default) The name of the representation
    #   that should be compiled using this rule
    #
    # @yield The block that will be executed when an item matching this
    #   compilation rule needs to be compiled
    #
    # @return [void]
    #
    # @example Compiling the default rep of a bunch of items
    #
    #     compile '/foo.*' do
    #       rep.filter :erb
    #     end
    #
    # @example Compiling the `:raw` rep of a bunch of items
    #
    #     compile '/articles/*', :rep => :raw do
    #       # do nothing
    #     end
    def compile(pattern, params={}, &block)
      # Require block
      raise ArgumentError.new("#compile requires a block") unless block_given?

      # Get rep name
      rep_name = params[:rep] || :default

      # Create rule
      rule = Rule.new(Nanoc::Pattern.from(pattern), rep_name, block)
      @rules_collection.add_item_compilation_rule(rule)
    end

    # Creates a routing rule for all items whose identifier match the
    # given pattern.
    #
    # This rule will be applicable to reps with a name equal to `:default`;
    # this can be changed by giving an explicit `:rep` parameter.
    #
    # @param [String] pattern A pattern matching identifiers of items that
    #   should be routed using this rule
    #
    # @option params [Symbol] :rep (:default) The name of the representation
    #   that should be routed using this rule
    #
    # @yield The block that will be executed when an item matching this
    #   compilation rule needs to be routed
    #
    # @return [void]
    #
    # @example Routing the default rep of an item
    #
    #     route '/foo.*' do
    #       item.identifier.in_dir.with_ext('html')
    #     end
    #
    # @example Routing the `:raw` rep of an item
    #
    #     route '/articles/*', :rep => :raw do
    #       item.identifier.prefix('raw').with_ext('txt')
    #     end
    def route(pattern, params={}, &block)
      # Require block
      raise ArgumentError.new("#route requires a block") unless block_given?

      # Get rep name
      rep_name      = params[:rep] || :default
      snapshot_name = params[:snapshot] || :last

      # Create rule
      rule = Rule.new(Nanoc::Pattern.from(pattern), rep_name, block, :snapshot_name => snapshot_name)
      @rules_collection.add_item_routing_rule(rule)
    end

    # Creates a layout rule for all layouts whose identifier match the given
    # identifier. The layouts matching the identifier will be filtered using
    # the filter specified in the second argument. The params hash contains
    # filter arguments that will be passed to the filter.
    #
    # @param [String, Regexp] pattern A pattern matching identifiers of layouts
    #   that should be filtered using this rule
    #
    # @param [Symbol] filter_name The name of the filter that should be run
    #   when processing the layout
    #
    # @param [Hash] params Extra filter arguments that should be passed to the
    #   filter when processing the layout (see {Nanoc::Filter#run})
    #
    # @return [void]
    #
    # @example Specifying the filter to use for a layout
    #
    #     layout '/default.*', :erb
    #
    # @example Using custom filter arguments for a layout
    #
    #     layout '/*.haml',  :haml, :format => :html5
    def layout(pattern, filter_name, params={})
      key = Nanoc::Pattern.from(pattern)
      value = [ filter_name, params ]
      @rules_collection.layout_filter_mapping[key] = value
    end

    # Creates a pair of compilation and routing rules that indicate that the
    # specified item(s) should be copied to the output folder as-is. The items
    # are selected using an identifier, which may either be a string
    # containing the `*` wildcard, or a regular expression.
    #
    # This meta-rule will be applicable to reps with a name equal to
    # `:default`; this can be changed by giving an explicit `:rep` parameter.
    #
    # @param [String, Regexp] pattern A pattern matching identifiers of items
    #   that should be processed using this meta-rule
    #
    # @option params [Symbol] :rep (:default) The name of the representation
    #   that should be routed using this rule
    #
    # @return [void]
    #
    # @since 3.2.0
    #
    # @example Copying items as-is
    #
    #     passthrough '/foo.*'
    #
    # @example Copying the `:raw` rep of the `/bar.html` item as-is
    #
    #     passthrough '/bar.html', :rep => :raw
    def passthrough(pattern, params={})
      # Require no block
      raise ArgumentError.new("#passthrough does not require a block") if block_given?

      # Get rep name
      rep_name = params[:rep] || :default

      # Create compilation rule
      compilation_block = proc { }
      compilation_rule = Rule.new(Nanoc::Pattern.from(pattern), rep_name, compilation_block)
      @rules_collection.add_item_compilation_rule(compilation_rule)

      # Create routing rule
      routing_block = proc do
        item.identifier
      end
      routing_rule = Rule.new(Nanoc::Pattern.from(pattern), rep_name, routing_block, :snapshot_name => :last)
      @rules_collection.add_item_routing_rule(routing_rule)
    end

    # Creates a pair of compilation and routing rules that indicate that the
    # specified item(s) should be ignored, e.g. compiled and routed with an
    # empty rule. The items are selected using an identifier, which may either
    # be a string containing the `*` wildcard, or a regular expression.
    #
    # This meta-rule will be applicable to reps with a name equal to
    # `:default`; this can be changed by giving an explicit `:rep` parameter.
    #
    # @param [String, Regexp] identifier A pattern matching identifiers of
    #   items that should be processed using this meta-rule
    #
    # @option params [Symbol] :rep (:default) The name of the representation
    #   that should be routed using this rule
    #
    # @return [void]
    #
    # @example Suppressing compilation and output for all all `/foo/*` items.
    #
    #     ignore '/foo/*'
    def ignore(pattern, params={})
      raise ArgumentError.new("#ignore does not require a block") if block_given?

      rep_name = params[:rep] || :default

      compilation_rule = Rule.new(Nanoc::Pattern.from(pattern), rep_name, proc { })
      @rules_collection.add_item_compilation_rule(compilation_rule)

      routing_rule = Rule.new(Nanoc::Pattern.from(pattern), rep_name, proc { }, :snapshot_name => :last)
      @rules_collection.add_item_routing_rule(routing_rule)
    end

    # Includes an additional rules file in the current rules collection.
    #
    # @param [String] name The name of the rules file — an ".rb" extension is
    #   implied if not explicitly given
    #
    # @return [void]
    #
    # @example Including two additional rules files, 'rules/assets.rb' and
    #   'rules/content.rb'
    #
    #     include_rules 'rules/assets'
    #     include_rules 'rules/content'
    def include_rules(name)
      filename = [ "#{name}", "#{name}.rb", "./#{name}", "./#{name}.rb" ].find { |f| File.file?(f) }
      raise Nanoc::Errors::NoRulesFileFound.new if filename.nil?

      self.instance_eval(File.read(filename), filename)
    end

  end

end
